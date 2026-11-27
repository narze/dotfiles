package main

import (
	"context"
	"encoding/json"
	"io"
	"os"
	"path/filepath"

	"github.com/coder/websocket"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestAccessKeyRequiredForDashboard(t *testing.T) {
	key := strings.Repeat("ab", 32)
	const origin = "https://updates.example.test"
	guard := newAccessGate(key, origin)
	handler := protect(guard.wrap(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})), origin, "owner")

	request := func(method, path, account string, form url.Values, cookie *http.Cookie) *httptest.ResponseRecorder {
		req := httptest.NewRequest(method, origin+path, strings.NewReader(form.Encode()))
		req.Header.Set("Tailscale-User-Login", account)
		if method == "POST" {
			req.Header.Set("Origin", origin)
			req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		}
		if cookie != nil {
			req.AddCookie(cookie)
		}
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		return rec
	}
	if got := request("GET", "/api/status", "owner", nil, nil).Code; got != http.StatusUnauthorized {
		t.Fatal(got)
	}
	if got := request("POST", "/login", "owner", url.Values{"key": {"bad"}}, nil).Code; got != http.StatusUnauthorized {
		t.Fatal(got)
	}
	rec := request("POST", "/login", "owner", url.Values{"key": {key}}, nil)
	if rec.Code != http.StatusSeeOther || len(rec.Result().Cookies()) != 1 {
		t.Fatal(rec.Code)
	}
	cookie := rec.Result().Cookies()[0]
	if !cookie.Secure || !cookie.HttpOnly || cookie.SameSite != http.SameSiteStrictMode {
		t.Fatal("insecure session cookie")
	}
	if got := request("GET", "/api/status", "owner", nil, cookie).Code; got != http.StatusNoContent {
		t.Fatal(got)
	}
	if got := request("GET", "/api/status", "other", nil, cookie).Code; got != http.StatusForbidden {
		t.Fatal(got)
	}
	cookie.Value += "X"
	if got := request("GET", "/api/status", "owner", nil, cookie).Code; got != http.StatusUnauthorized {
		t.Fatal(got)
	}
}

func TestTerminalTicketOwnerAndReplay(t *testing.T) {
	tickets := terminalTickets{}
	now := time.Now()
	key, err := tickets.issue(terminalTicket{user: "owner", session: "session", mode: "shell", expires: now.Add(time.Minute)}, now)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := tickets.take(key, "owner", "different", now); ok {
		t.Fatal("different session accepted")
	}
	if _, ok := tickets.take(key, "owner", "session", now); !ok {
		t.Fatal("valid ticket refused")
	}
	if _, ok := tickets.take(key, "owner", "session", now); ok {
		t.Fatal("ticket replayed")
	}
	key, err = tickets.issue(terminalTicket{user: "owner", session: "session", mode: "shell", expires: now.Add(time.Minute)}, now)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := tickets.take(key, "owner", "session", now.Add(time.Minute)); ok {
		t.Fatal("expired ticket accepted")
	}
}

func TestTerminalRunsShellAndReviewedBrewCommand(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("HOME", dir)
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("TERMINAL_TEST_LOG", filepath.Join(dir, "brew.log"))
	stub := `#!/bin/sh
if [ "$1" = outdated ]; then
  printf '%s\n' '{"formulae":[{"name":"fixture","installed_versions":["1"],"current_version":"2"},{"name":"other","installed_versions":["1"],"current_version":"2"}],"casks":[]}'
  exit 0
fi
case "$*" in
  *--dry-run*) echo "fixture dry run"; exit 0;;
esac
printf '%s\n' "$*" > "$TERMINAL_TEST_LOG"
printf "fixture prompt> "
IFS= read -r value
printf '\nanswered: %s\n' "$value"
`
	if err := os.WriteFile(filepath.Join(dir, "brew"), []byte(stub), 0700); err != nil {
		t.Fatal(err)
	}
	d := newDashboard(map[string]updater{"brew": homebrew{}})
	service := &terminalServer{dashboard: d, shell: "/bin/sh"}
	server := httptest.NewUnstartedServer(nil)
	origin := "http://" + server.Listener.Addr().String()
	service.origin = origin
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/terminal", service.connect)
	mux.HandleFunc("POST /api/terminal-ticket", service.issue)
	server.Config.Handler = protect(mux, origin, "owner")
	server.Start()
	defer server.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()

	sockURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/api/terminal"
	if ws, res, err := websocket.Dial(ctx, sockURL, &websocket.DialOptions{HTTPHeader: http.Header{
		"Origin": {"https://different.example"}, "Tailscale-User-Login": {"owner"},
	}}); err == nil || res == nil || res.StatusCode != http.StatusForbidden {
		if ws != nil {
			ws.CloseNow()
		}
		t.Fatalf("cross-origin socket was not denied: %v", err)
	}

	open := func(mode, preview string) *websocket.Conn {
		t.Helper()
		raw, _ := json.Marshal(map[string]string{"mode": mode, "preview": preview})
		req, err := http.NewRequestWithContext(ctx, "POST", server.URL+"/api/terminal-ticket", strings.NewReader(string(raw)))
		if err != nil {
			t.Fatal(err)
		}
		req.Header.Set("Origin", origin)
		req.Header.Set("Tailscale-User-Login", "owner")
		req.Header.Set("X-Update-Request", "1")
		res, err := server.Client().Do(req)
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		var response map[string]string
		if err := json.NewDecoder(res.Body).Decode(&response); err != nil || res.StatusCode != http.StatusOK {
			t.Fatalf("ticket: %s (%v)", res.Status, err)
		}
		ws, _, err := websocket.Dial(ctx, sockURL, &websocket.DialOptions{HTTPHeader: http.Header{
			"Origin": {origin}, "Tailscale-User-Login": {"owner"},
		}})
		if err != nil {
			t.Fatal(err)
		}
		sendTerminalTestMessage(t, ctx, ws, terminalMessage{Type: "open", Ticket: response["ticket"], Cols: 80, Rows: 24})
		return ws
	}

	shell := open("shell", "")
	defer shell.CloseNow()
	sendTerminalTestMessage(t, ctx, shell, terminalMessage{Type: "input", Data: "printf '%s%s\\n' shell- ready; exit\n"})
	output := readTerminalTest(t, ctx, shell)
	if !strings.Contains(output, "\r\nshell-ready\r\n") {
		t.Fatalf("shell output: %q", output)
	}

	preview, err := d.preview(ctx, "brew", &packageTarget{Name: "fixture", Kind: "Formula"})
	if err != nil {
		t.Fatal(err)
	}
	brew := open("brew", preview.Token)
	defer brew.CloseNow()
	sendTerminalTestMessage(t, ctx, brew, terminalMessage{Type: "input", Data: "confirmed\n"})
	output = readTerminalTest(t, ctx, brew)
	if !strings.Contains(output, "answered: confirmed") {
		t.Fatalf("brew output: %q", output)
	}
	raw, err := os.ReadFile(filepath.Join(dir, "brew.log"))
	if err != nil || strings.TrimSpace(string(raw)) != "upgrade --no-ask --formula -- fixture" {
		t.Fatalf("brew command: %q (%v)", raw, err)
	}
}

func sendTerminalTestMessage(t *testing.T, ctx context.Context, ws *websocket.Conn, msg terminalMessage) {
	t.Helper()
	data, _ := json.Marshal(msg)
	if err := ws.Write(ctx, websocket.MessageText, data); err != nil {
		t.Fatal(err)
	}
}

func readTerminalTest(t *testing.T, ctx context.Context, ws *websocket.Conn) string {
	t.Helper()
	var output strings.Builder
	for {
		kind, data, err := ws.Read(ctx)
		if err != nil && err != io.EOF {
			t.Fatalf("read terminal: %v, output %q", err, output.String())
		}
		if kind == websocket.MessageBinary {
			output.Write(data)
			continue
		}
		var msg terminalMessage
		if json.Unmarshal(data, &msg) != nil {
			t.Fatalf("terminal event: %q", data)
		}
		switch msg.Type {
		case "error":
			t.Fatal(msg.Data)
		case "done":
			return output.String()
		}
	}
}
