package main

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestGitHubSignInOnlyAllowsOwner(t *testing.T) {
	for _, userID := range []int{248741, 1234} {
		t.Run(fmt.Sprint(userID), func(t *testing.T) {
			const origin = "https://updates.example.test"
			var challenge string
			exchanges := 0
			github := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				switch r.URL.Path {
				case "/token":
					exchanges++
					if err := r.ParseForm(); err != nil {
						t.Fatal(err)
					}
					hash := sha256.Sum256([]byte(r.Form.Get("code_verifier")))
					if base64.RawURLEncoding.EncodeToString(hash[:]) != challenge ||
						r.Form.Get("redirect_uri") != origin+"/auth/github/callback" ||
						r.Form.Get("client_secret") != "test-secret" || r.Form.Get("code") != "code" {
						t.Error("Invalid token exchange")
						http.Error(w, "Invalid", 400)
						return
					}
					fmt.Fprint(w, `{"access_token":"test-token","token_type":"bearer"}`)
				case "/user":
					if r.Header.Get("Authorization") != "Bearer test-token" {
						t.Error("Missing API authorization")
					}
					fmt.Fprintf(w, `{"id":%d}`, userID)
				default:
					http.NotFound(w, r)
				}
			}))
			defer github.Close()
			gate := newAccessGate("", origin)
			gate.github = &githubLogin{ClientID: "test-id", ClientSecret: "test-secret", OwnerID: 248741,
				authorizeURL: github.URL + "/authorize", tokenURL: github.URL + "/token", userURL: github.URL + "/user"}
			handler := protect(gate.wrap(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(204) })), origin, "owner")
			request := func(method, path, account string, cookie *http.Cookie) *httptest.ResponseRecorder {
				r := httptest.NewRequest(method, origin+path, nil)
				r.Header.Set("Tailscale-User-Login", account)
				r.Header.Set("Origin", origin)
				if cookie != nil {
					r.AddCookie(cookie)
				}
				w := httptest.NewRecorder()
				handler.ServeHTTP(w, r)
				return w
			}
			loginPage := request("GET", "/login", "owner", nil)
			if policy := loginPage.Header().Get("Referrer-Policy"); policy != "same-origin" {
				t.Fatalf("login document needs a policy that preserves its form Origin: %q", policy)
			}
			if policy := loginPage.Header().Get("Content-Security-Policy"); !strings.Contains(policy, "form-action 'self' https://github.com;") {
				t.Fatalf("login document must allow the GitHub form redirect: %q", policy)
			}
			for _, referrer := range []string{"null", "https://other.test"} {
				req := httptest.NewRequest(http.MethodPost, origin+"/login", nil)
				req.Header.Set("Tailscale-User-Login", "owner")
				req.Header.Set("Origin", referrer)
				rec := httptest.NewRecorder()
				handler.ServeHTTP(rec, req)
				if rec.Code != http.StatusForbidden {
					t.Fatalf("login accepted Origin %q: %d", referrer, rec.Code)
				}
			}

			start := request("POST", "/login", "owner", nil)
			dest, err := url.Parse(start.Header().Get("Location"))
			if err != nil || start.Code != 303 {
				t.Fatalf("bad OAuth redirect: %d", start.Code)
			}
			q := dest.Query()
			state := q.Get("state")
			challenge = q.Get("code_challenge")
			if len(state) < 32 || len(challenge) != 43 || q.Get("code_challenge_method") != "S256" || q.Get("scope") != "" {
				t.Fatal("OAuth request lacks bounded state or PKCE")
			}
			cookies := start.Result().Cookies()
			if len(cookies) != 1 || !cookies[0].Secure || !cookies[0].HttpOnly || cookies[0].SameSite != http.SameSiteLaxMode {
				t.Fatal("Invalid state cookie")
			}
			bad := request("GET", "/auth/github/callback?state=wrong&code=code", "owner", cookies[0])
			if bad.Code != 400 || exchanges != 0 {
				t.Fatalf("accepted mismatched state: %d", bad.Code)
			}
			result := request("GET", "/auth/github/callback?state="+url.QueryEscape(state)+"&code=code", "owner", cookies[0])
			if userID != 248741 {
				if result.Code != 403 || strings.Contains(result.Header().Get("Set-Cookie"), sessionCookie+"=") {
					t.Fatal("signed in another GitHub account")
				}
				return
			}
			var session *http.Cookie
			for _, c := range result.Result().Cookies() {
				if c.Name == sessionCookie {
					session = c
				}
			}
			if result.Code != 303 || session == nil {
				t.Fatalf("owner login failed: %d", result.Code)
			}
			if result := request("GET", "/api/status", "owner", session); result.Code != 204 {
				t.Fatal(result.Code)
			}
			if result := request("GET", "/api/status", "other", session); result.Code != 403 {
				t.Fatal(result.Code)
			}
		})
	}
}
