package main

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

const githubCallback = "/auth/github/callback"
const githubCookie = "__Host-host-updates-github"

type githubLogin struct {
	ClientID                        string `json:"clientId"`
	ClientSecret                    string `json:"clientSecret"`
	OwnerID                         int64  `json:"ownerId"`
	authorizeURL, tokenURL, userURL string
}

func loadGitHubLogin(path string) (*githubLogin, error) {
	raw, err := readPrivateFile(path)
	if err != nil {
		return nil, err
	}
	var config githubLogin
	if err := json.Unmarshal(raw, &config); err != nil || config.ClientID == "" || config.ClientSecret == "" || config.OwnerID <= 0 {
		return nil, errors.New("GitHub auth file needs clientId, clientSecret, and a numeric ownerId")
	}
	config.authorizeURL = "https://github.com/login/oauth/authorize"
	config.tokenURL = "https://github.com/login/oauth/access_token"
	config.userURL = "https://api.github.com/user"
	return &config, nil
}

func (g accessGate) startGitHub(w http.ResponseWriter, r *http.Request) {
	var stateBytes, verifierBytes [32]byte
	rand.Read(stateBytes[:])
	rand.Read(verifierBytes[:])
	state := base64.RawURLEncoding.EncodeToString(stateBytes[:])
	verifier := base64.RawURLEncoding.EncodeToString(verifierBytes[:])
	challenge := sha256.Sum256([]byte(verifier))
	expires := time.Now().Add(10 * time.Minute)
	body := strings.Join([]string{state, verifier, strconv.FormatInt(expires.Unix(), 10)}, ":")
	cookie := githubFlowCookie(body + "." + g.tag("github:"+body, identity(r)))
	cookie.Expires = expires
	http.SetCookie(w, cookie)
	args := url.Values{
		"client_id":             {g.github.ClientID},
		"redirect_uri":          {g.origin + githubCallback},
		"state":                 {state},
		"code_challenge":        {base64.RawURLEncoding.EncodeToString(challenge[:])},
		"code_challenge_method": {"S256"},
		"allow_signup":          {"false"},
	}
	http.Redirect(w, r, g.github.authorizeURL+"?"+args.Encode(), http.StatusSeeOther)
}

func githubFlowCookie(value string) *http.Cookie {
	return &http.Cookie{Name: githubCookie, Value: value, Path: "/", Secure: true, HttpOnly: true, SameSite: http.SameSiteLaxMode}
}

func (g accessGate) githubCallback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.Header().Set("Allow", "GET")
		http.Error(w, "Method not allowed.", http.StatusMethodNotAllowed)
		return
	}
	expired := githubFlowCookie("")
	expired.MaxAge = -1
	http.SetCookie(w, expired)
	verifier, ok := g.githubVerifier(r)
	if !ok || r.URL.Query().Get("code") == "" {
		http.Error(w, "GitHub sign-in expired or was cancelled. Go back to sign in again.", http.StatusBadRequest)
		return
	}
	userID, err := g.github.account(r, g.origin+githubCallback, verifier)
	if err != nil {
		http.Error(w, "GitHub sign-in failed. Go back to try again.", http.StatusBadGateway)
		return
	}
	if userID != g.github.OwnerID {
		http.Error(w, "This GitHub account cannot access Host updates.", http.StatusForbidden)
		return
	}
	g.signIn(w, r, http.SameSiteLaxMode)
}

func (g accessGate) githubVerifier(r *http.Request) (string, bool) {
	cookie, err := r.Cookie(githubCookie)
	if err != nil {
		return "", false
	}
	body, tag, ok := strings.Cut(cookie.Value, ".")
	if !ok || !hmac.Equal([]byte(tag), []byte(g.tag("github:"+body, identity(r)))) {
		return "", false
	}
	fields := strings.Split(body, ":")
	if len(fields) != 3 || !hmac.Equal([]byte(fields[0]), []byte(r.URL.Query().Get("state"))) {
		return "", false
	}
	expires, err := strconv.ParseInt(fields[2], 10, 64)
	return fields[1], err == nil && time.Now().Unix() < expires
}

func (g *githubLogin) account(r *http.Request, callback, verifier string) (int64, error) {
	client := &http.Client{
		Timeout:       8 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	form := url.Values{
		"client_id":     {g.ClientID},
		"client_secret": {g.ClientSecret},
		"code":          {r.URL.Query().Get("code")},
		"redirect_uri":  {callback},
		"code_verifier": {verifier},
	}
	exchange, err := http.NewRequestWithContext(r.Context(), http.MethodPost, g.tokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return 0, err
	}
	exchange.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	var token struct {
		AccessToken string `json:"access_token"`
		Type        string `json:"token_type"`
	}
	if err := githubJSON(client, exchange, &token); err != nil {
		return 0, err
	}
	if token.AccessToken == "" || !strings.EqualFold(token.Type, "bearer") {
		return 0, errors.New("GitHub returned no usable access token")
	}
	profile, err := http.NewRequestWithContext(r.Context(), http.MethodGet, g.userURL, nil)
	if err != nil {
		return 0, err
	}
	profile.Header.Set("Authorization", "Bearer "+token.AccessToken)
	var account struct {
		ID int64 `json:"id"`
	}
	if err := githubJSON(client, profile, &account); err != nil {
		return 0, err
	}
	return account.ID, nil
}

func githubJSON(client *http.Client, req *http.Request, result any) error {
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "host-updates")
	response, err := client.Do(req)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return errors.New("GitHub rejected the request")
	}
	return json.NewDecoder(io.LimitReader(response.Body, 64<<10)).Decode(result)
}
