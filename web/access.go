package main

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const sessionCookie = "__Host-host-updates"

type accessGate struct {
	key, origin string
	signingKey  [32]byte
	github      *githubLogin
}

func newAccessGate(key, origin string) accessGate {
	g := accessGate{key: key, origin: origin}
	rand.Read(g.signingKey[:])
	return g
}

func readPrivateFile(path string) ([]byte, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return nil, err
	}
	owner, ok := info.Sys().(*syscall.Stat_t)
	if !info.Mode().IsRegular() || info.Mode().Perm()&0077 != 0 || !ok || int(owner.Uid) != os.Geteuid() {
		return nil, fmt.Errorf("authentication file must be a private regular file owned by the service user")
	}
	return os.ReadFile(path)
}

func accessKey(path string) (string, error) {
	raw, err := readPrivateFile(path)
	if err != nil {
		return "", err
	}
	value := strings.TrimSpace(string(raw))
	if decoded, err := hex.DecodeString(value); err != nil || len(decoded) != 32 {
		return "", fmt.Errorf("access key must be exactly 32 bytes of hex")
	}
	return value, nil
}

func privateListener(path string) (net.Listener, error) {
	dir, err := os.Lstat(filepath.Dir(path))
	if err != nil {
		return nil, err
	}
	owner, ok := dir.Sys().(*syscall.Stat_t)
	if !filepath.IsAbs(path) || !dir.IsDir() || dir.Mode().Perm() != 0700 || !ok || int(owner.Uid) != os.Geteuid() {
		return nil, fmt.Errorf("Unix socket requires an absolute path in a 0700 directory owned by the service user")
	}
	listener, err := net.Listen("unix", path)
	if err != nil {
		return nil, err
	}
	if err := os.Chmod(path, 0600); err != nil {
		listener.Close()
		return nil, err
	}
	return listener, nil
}

func (g accessGate) tag(value, user string) string {
	mac := hmac.New(sha256.New, g.signingKey[:])
	fmt.Fprint(mac, value, "\n", user)
	return hex.EncodeToString(mac.Sum(nil))
}

func identity(r *http.Request) string { return r.Header.Get("Tailscale-User-Login") }

func sessionID(r *http.Request) string {
	if cookie, err := r.Cookie(sessionCookie); err == nil {
		return cookie.Value
	}
	return ""
}

func (g accessGate) valid(r *http.Request) bool {
	body, tag, ok := strings.Cut(sessionID(r), ".")
	if !ok || !hmac.Equal([]byte(tag), []byte(g.tag(body, identity(r)))) {
		return false
	}
	expiry, _, _ := strings.Cut(body, ":")
	expires, err := strconv.ParseInt(expiry, 10, 64)
	return err == nil && time.Now().Unix() < expires
}

func (g accessGate) wrap(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/login" {
			g.login(w, r)
			return
		}
		if g.github != nil && r.URL.Path == githubCallback {
			g.githubCallback(w, r)
			return
		}
		if !g.valid(r) {
			if r.Method == http.MethodGet && (r.URL.Path == "/" || r.URL.Path == "/terminal") {
				http.Redirect(w, r, "/login", http.StatusSeeOther)
			} else {
				http.Error(w, "Sign in to Host updates.", http.StatusUnauthorized)
			}
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (g accessGate) login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	switch r.Method {
	case http.MethodPost:
		if r.Header.Get("Origin") != g.origin {
			http.Error(w, "Request origin denied.", http.StatusForbidden)
			return
		}
		if g.github != nil {
			g.startGitHub(w, r)
			return
		}
		r.Body = http.MaxBytesReader(w, r.Body, 512)
		if r.ParseForm() != nil || subtle.ConstantTimeCompare([]byte(r.PostForm.Get("key")), []byte(g.key)) != 1 {
			w.WriteHeader(http.StatusUnauthorized)
			io.WriteString(w, loginPage("<p role=alert>That access key was not accepted.</p>"))
			return
		}
		g.signIn(w, r, http.SameSiteStrictMode)
	case http.MethodGet:
		// The login form needs its Origin on same-origin browser submissions.
		w.Header().Set("Referrer-Policy", "same-origin")
		if g.github != nil {
			w.Header().Set("Content-Security-Policy", contentSecurityPolicy(r.Host, true))
			io.WriteString(w, pageWithLoginForm(`<form method=post action=/login><button>Sign in with GitHub</button></form>`))
			return
		}
		io.WriteString(w, loginPage(""))
	default:
		w.Header().Set("Allow", "GET, POST")
		http.Error(w, "Method not allowed.", http.StatusMethodNotAllowed)
	}
}

func (g accessGate) signIn(w http.ResponseWriter, r *http.Request, sameSite http.SameSite) {
	expires := time.Now().Add(8 * time.Hour)
	var nonce [16]byte
	rand.Read(nonce[:])
	body := strconv.FormatInt(expires.Unix(), 10) + ":" + hex.EncodeToString(nonce[:])
	http.SetCookie(w, &http.Cookie{Name: sessionCookie, Value: body + "." + g.tag(body, identity(r)), Path: "/", Expires: expires, Secure: true, HttpOnly: true, SameSite: sameSite})
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func loginPage(message string) string {
	return pageWithLoginForm(message + `<form method=post action=/login><label>Access key <input name=key type=password maxlength=64 required></label> <button>Sign in</button></form>`)
}

func pageWithLoginForm(form string) string {
	return `<!doctype html><html lang=en><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><title>Sign in · Host updates</title><main><h1>Sign in to Host updates</h1>` + form + `</main></html>`
}
