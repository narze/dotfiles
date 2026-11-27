package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"os/exec"
	"slices"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/coder/websocket"
	"github.com/creack/pty"
)

type terminalTicket struct {
	user, session, mode, preview string
	expires                      time.Time
}

type terminalTickets struct {
	mu      sync.Mutex
	pending map[string]terminalTicket
}

func (t *terminalTickets) issue(item terminalTicket, now time.Time) (string, error) {
	var data [24]byte
	if _, err := rand.Read(data[:]); err != nil {
		return "", err
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.pending == nil {
		t.pending = make(map[string]terminalTicket)
	}
	for key, pending := range t.pending {
		if !now.Before(pending.expires) {
			delete(t.pending, key)
		}
	}
	if len(t.pending) >= 16 {
		return "", errors.New("Too many pending terminal requests. Try again shortly.")
	}
	token := hex.EncodeToString(data[:])
	t.pending[token] = item
	return token, nil
}

func (t *terminalTickets) take(token, user, session string, now time.Time) (terminalTicket, bool) {
	t.mu.Lock()
	defer t.mu.Unlock()
	item, ok := t.pending[token]
	if !ok || user != item.user || session != item.session || !now.Before(item.expires) {
		return terminalTicket{}, false
	}
	delete(t.pending, token)
	return item, true
}

type terminalServer struct {
	dashboard     *dashboard
	origin, shell string
	tickets       terminalTickets
}

type terminalMessage struct {
	Type   string `json:"type"`
	Ticket string `json:"ticket,omitempty"`
	Data   string `json:"data,omitempty"`
	Cols   uint16 `json:"cols,omitempty"`
	Rows   uint16 `json:"rows,omitempty"`
}

func (m terminalMessage) size() *pty.Winsize {
	return &pty.Winsize{Cols: min(500, max(2, m.Cols)), Rows: min(250, max(2, m.Rows))}
}

func (s *terminalServer) issue(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("Origin") != s.origin {
		http.Error(w, "Request origin denied.", http.StatusForbidden)
		return
	}
	var request struct {
		Mode    string `json:"mode"`
		Preview string `json:"preview"`
	}
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 512))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil || decoder.Decode(new(any)) != io.EOF ||
		(request.Mode != "shell" && request.Mode != "brew") || (request.Mode == "brew") != (request.Preview != "") {
		http.Error(w, "Invalid terminal request.", http.StatusBadRequest)
		return
	}
	now := time.Now()
	key, err := s.tickets.issue(terminalTicket{user: identity(r), session: sessionID(r), mode: request.Mode, preview: request.Preview, expires: now.Add(45 * time.Second)}, now)
	if err != nil {
		http.Error(w, "Could not reserve a terminal. Try again shortly.", http.StatusServiceUnavailable)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"ticket": key})
}

func terminalEvent(ws *websocket.Conn, kind, message string) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	data, _ := json.Marshal(terminalMessage{Type: kind, Data: message})
	_ = ws.Write(ctx, websocket.MessageText, data)
}

func (s *terminalServer) connect(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("Origin") != s.origin {
		http.Error(w, "Request origin denied.", http.StatusForbidden)
		return
	}
	user, session := identity(r), sessionID(r)
	ws, err := websocket.Accept(w, r, nil)
	if err != nil {
		return
	}
	defer ws.CloseNow()
	ws.SetReadLimit(64 << 10)
	handshake, cancelHandshake := context.WithTimeout(context.Background(), 5*time.Second)
	kind, data, err := ws.Read(handshake)
	cancelHandshake()
	var first terminalMessage
	if err != nil || kind != websocket.MessageText || json.Unmarshal(data, &first) != nil || first.Type != "open" {
		terminalEvent(ws, "error", "Terminal authorization failed.")
		return
	}
	ticket, ok := s.tickets.take(first.Ticket, user, session, time.Now())
	if !ok {
		terminalEvent(ws, "error", "Terminal authorization expired or was already used.")
		return
	}
	label := "shell"
	if ticket.mode == "brew" {
		label = "apply brew"
	}
	if !s.dashboard.begin(label) {
		terminalEvent(ws, "error", "Another operation is running. Try again when it finishes.")
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Hour)
	defer cancel()
	defer ws.Close(websocket.StatusNormalClosure, "")
	if ticket.mode == "shell" {
		cmd := exec.CommandContext(ctx, s.shell, "-il")
		cmd.Env = append(os.Environ(), "TERM=xterm-256color")
		cmd.Dir, _ = os.UserHomeDir()
		terminalEvent(ws, "ready", "Shell connected.")
		err := runTerminal(ctx, cancel, ws, cmd, first.size(), true)
		s.dashboard.finish("Terminal closed.", false)
		if err != nil && ctx.Err() == nil {
			terminalEvent(ws, "error", "Shell exited with an error.")
		} else {
			terminalEvent(ws, "done", "Shell closed.")
		}
		return
	}

	err = s.upgrade(ctx, cancel, ws, ticket.preview, first.size())
	message := "Homebrew update finished."
	if err != nil {
		message = err.Error()
	} else {
		checkCtx, stop := context.WithTimeout(context.Background(), 30*time.Second)
		defer stop()
		if checkErr := s.dashboard.checkBrewInventory(checkCtx); checkErr != nil {
			message = "Homebrew update finished. Run Check now to refresh the list."
		}
	}
	s.dashboard.finish(message, err != nil)
	if err != nil {
		terminalEvent(ws, "error", message)
	} else {
		terminalEvent(ws, "done", message)
	}
}

func (s *terminalServer) upgrade(ctx context.Context, cancel context.CancelFunc, ws *websocket.Conn, token string, size *pty.Winsize) error {
	terminalEvent(ws, "status", "Rechecking the approved Homebrew preview…")
	plan, err := s.dashboard.reviewedPlan(ctx, "brew", token, true)
	if err != nil {
		return err
	}
	if len(plan.Inventory.Changes) != 1 {
		return errPreviewChanged
	}
	item := plan.Inventory.Changes[0]
	flag := "--formula"
	if item.Kind == "Cask" {
		flag = "--cask"
	}
	if item.Pinned || !packageName.MatchString(item.Name) {
		return errPreviewChanged
	}
	cmd := exec.CommandContext(ctx, "brew", "upgrade", "--no-ask", flag, "--", item.Name)
	env := slices.DeleteFunc(os.Environ(), func(value string) bool {
		return strings.HasPrefix(value, "NONINTERACTIVE=") || strings.HasPrefix(value, "NO_COLOR=")
	})
	cmd.Env = append(env, "HOMEBREW_NO_AUTO_UPDATE=1", "TERM=xterm-256color")
	terminalEvent(ws, "ready", "Upgrading "+item.Name+"…")
	if err := runTerminal(ctx, cancel, ws, cmd, size, false); err != nil {
		return errors.New("Homebrew did not finish the upgrade. Check the terminal output before retrying.")
	}
	return nil
}

func runTerminal(ctx context.Context, cancel context.CancelFunc, ws *websocket.Conn, cmd *exec.Cmd, size *pty.Winsize, closeOnDisconnect bool) error {
	cmd.Cancel = func() error { return syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL) }
	tty, err := pty.StartWithSize(cmd, size)
	if err != nil {
		return err
	}
	defer tty.Close()

	go func() {
		if closeOnDisconnect {
			defer cancel()
		}
		for {
			kind, data, err := ws.Read(ctx)
			if err != nil {
				return
			}
			var input terminalMessage
			if kind != websocket.MessageText || json.Unmarshal(data, &input) != nil {
				_ = ws.Close(websocket.StatusPolicyViolation, "Invalid input")
				return
			}
			switch input.Type {
			case "input":
				if _, err := io.WriteString(tty, input.Data); err != nil {
					return
				}
			case "resize":
				_ = pty.Setsize(tty, input.size())
			}
		}
	}()

	outputDone := make(chan struct{})
	go func() {
		defer close(outputDone)
		var buffer [8192]byte
		connected := true
		for {
			n, readErr := tty.Read(buffer[:])
			if n > 0 && connected {
				writeCtx, stop := context.WithTimeout(ctx, 5*time.Second)
				err := ws.Write(writeCtx, websocket.MessageBinary, buffer[:n])
				stop()
				connected = err == nil
				if !connected && closeOnDisconnect {
					cancel()
				}
			}
			if readErr != nil {
				return
			}
		}
	}()

	err = cmd.Wait()
	select {
	case <-outputDone:
	case <-time.After(time.Second):
		_ = tty.Close()
	}
	return err
}
