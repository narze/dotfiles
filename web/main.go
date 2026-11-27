package main

import (
	"encoding/json"
	"flag"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"time"
)

func protect(next http.Handler, publicOrigin, tailscaleUser string) http.Handler {
	origin, _ := url.Parse(publicOrigin)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("Referrer-Policy", "no-referrer")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Content-Security-Policy", contentSecurityPolicy(origin.Host, false))
		if r.Host != origin.Host || (tailscaleUser != "" && r.Header.Get("Tailscale-User-Login") != tailscaleUser) {
			http.Error(w, "Access denied.", http.StatusForbidden)
			return
		}
		if r.Method == http.MethodPost && r.URL.Path != "/login" && (r.Header.Get("X-Update-Request") != "1" ||
			(r.Header.Get("Origin") != "" && r.Header.Get("Origin") != publicOrigin)) {
			http.Error(w, "Request origin denied.", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func contentSecurityPolicy(host string, githubSignIn bool) string {
	formAction := "'self'"
	if githubSignIn {
		formAction += " https://github.com"
	}
	return "default-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action " + formAction +
		"; connect-src 'self' wss://" + host + "; style-src 'self' 'unsafe-inline'"
}

func (d *dashboard) routes(assets, hostname string, interval time.Duration, terminal *terminalServer) *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	mux.HandleFunc("GET /api/status", func(w http.ResponseWriter, r *http.Request) {
		d.mu.Lock()
		defer d.mu.Unlock()
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"host": hostname, "sections": d.sections, "busy": d.busy, "last": d.last,
			"intervalMinutes": int(interval.Minutes()), "terminal": terminal != nil,
		})
	})
	mux.HandleFunc("POST /api/{operation}", func(w http.ResponseWriter, r *http.Request) {
		var request struct {
			Section string         `json:"section"`
			Token   string         `json:"token"`
			Package *packageTarget `json:"package"`
		}
		decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1024))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&request); err != nil || decoder.Decode(new(any)) != io.EOF {
			http.Error(w, "Invalid request.", http.StatusBadRequest)
			return
		}
		operation := r.PathValue("operation")
		if target := request.Package; target != nil &&
			(operation != "preview" || request.Section != "brew" ||
				(target.Kind != "Formula" && target.Kind != "Cask") || !packageName.MatchString(target.Name)) {
			http.Error(w, "Invalid Homebrew package selection.", http.StatusBadRequest)
			return
		}
		switch operation {
		case "check":
			request.Section = ""
		case "preview", "apply":
			if _, ok := d.backends[request.Section]; !ok {
				http.Error(w, "Unknown update section.", http.StatusBadRequest)
				return
			}
		default:
			http.NotFound(w, r)
			return
		}
		if !d.start(operation, request.Section, request.Token, request.Package) {
			http.Error(w, "Another operation is running.", http.StatusConflict)
			return
		}
		w.WriteHeader(http.StatusAccepted)
	})
	if terminal != nil {
		mux.HandleFunc("POST /api/terminal-ticket", terminal.issue)
		mux.HandleFunc("GET /api/terminal", terminal.connect)
		mux.HandleFunc("GET /terminal", func(w http.ResponseWriter, r *http.Request) {
			http.ServeFile(w, r, filepath.Join(assets, "index.html"))
		})
	}
	mux.Handle("GET /", http.FileServer(http.Dir(assets)))
	return mux
}

func envDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatal(err)
	}
	listen := flag.String("listen", envDefault("HOST_UPDATES_LISTEN", "127.0.0.1:8780"), "loopback address")
	repo := flag.String("repo", envDefault("HOST_UPDATES_REPO", filepath.Join(home, ".local/share/chezmoi")), "chezmoi Git checkout")
	chezmoi := flag.String("chezmoi", envDefault("HOST_UPDATES_CHEZMOI", "chezmoi"), "chezmoi executable to use")
	assets := flag.String("assets", envDefault("HOST_UPDATES_ASSETS", "dist"), "built Svelte assets")
	interval := flag.Duration("interval", time.Hour, "delay between automatic checks")
	publicOrigin := flag.String("origin", os.Getenv("HOST_UPDATES_ORIGIN"), "HTTPS origin via Tailscale Serve")
	socket := flag.String("unix-socket", "", "private Unix socket to serve instead of TCP")
	githubAuthFile := flag.String("github-auth-file", os.Getenv("HOST_UPDATES_GITHUB_AUTH_FILE"), "private GitHub OAuth configuration file")
	keyFile := flag.String("access-key-file", "", "private file with a 32-byte hex access key")
	shell := flag.String("shell", os.Getenv("HOST_UPDATES_SHELL"), "absolute login shell path, enables terminals with protected access")
	tailscaleUser := flag.String("tailscale-user", os.Getenv("HOST_UPDATES_TAILSCALE_USER"), "allowed Tailscale login when using Serve")
	flag.Parse()
	host, _, err := net.SplitHostPort(*listen)
	if err != nil || net.ParseIP(host) == nil || !net.ParseIP(host).IsLoopback() {
		log.Fatal("listen must be a loopback IP and port")
	}
	if *interval < time.Minute {
		log.Fatal("interval must be at least one minute")
	}
	if *publicOrigin == "" {
		if *tailscaleUser != "" {
			log.Fatal("tailscale-user requires an HTTPS origin")
		}
		*publicOrigin = "http://" + *listen
	} else {
		u, err := url.Parse(*publicOrigin)
		if err != nil || u.Scheme != "https" || u.Host == "" || *publicOrigin != "https://"+u.Host || *tailscaleUser == "" {
			log.Fatal("Serve needs an HTTPS origin without a path and an allowed Tailscale login")
		}
	}
	if _, err := os.Stat(filepath.Join(*assets, "index.html")); err != nil {
		log.Fatal("build the Svelte UI with npm ci and npm run build")
	}

	if (*socket != "" || *keyFile != "" || *githubAuthFile != "" || *shell != "") && *tailscaleUser == "" {
		log.Fatal("protected terminal options require Tailscale Serve")
	}
	if *shell != "" && (!filepath.IsAbs(*shell) || (*socket == "" && *keyFile == "" && *githubAuthFile == "")) {
		log.Fatal("an absolute shell path and protected authentication are required")
	}
	if *keyFile != "" && *githubAuthFile != "" {
		log.Fatal("choose one dashboard sign-in method")
	}
	var gate *accessGate
	if *githubAuthFile != "" {
		config, err := loadGitHubLogin(*githubAuthFile)
		if err != nil {
			log.Fatal(err)
		}
		configured := newAccessGate("", *publicOrigin)
		configured.github = config
		gate = &configured
	}
	if *keyFile != "" {
		key, err := accessKey(*keyFile)
		if err != nil {
			log.Fatal(err)
		}
		configured := newAccessGate(key, *publicOrigin)
		gate = &configured
	}
	hostname, _ := os.Hostname()
	d := newDashboard(map[string]updater{"dotfiles": dotfiles{repo: *repo, binary: *chezmoi}, "brew": homebrew{}})
	var terminal *terminalServer
	if *shell != "" {
		terminal = &terminalServer{dashboard: d, origin: *publicOrigin, shell: *shell}
	}
	var handler http.Handler = d.routes(*assets, hostname, *interval, terminal)
	if gate != nil {
		handler = gate.wrap(handler)
	}
	server := &http.Server{
		Handler:           protect(handler, *publicOrigin, *tailscaleUser),
		ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 10 * time.Second, WriteTimeout: 15 * time.Second,
	}
	var listener net.Listener
	if *socket != "" {
		listener, err = privateListener(*socket)
	} else {
		listener, err = net.Listen("tcp", *listen)
	}
	if err != nil {
		log.Fatal(err)
	}
	d.start("check", "", "", nil)
	go func() {
		ticker := time.NewTicker(*interval)
		defer ticker.Stop()
		for range ticker.C {
			d.start("check", "", "", nil)
		}
	}()
	log.Printf("Host Updates at %s", *publicOrigin)
	log.Fatal(server.Serve(listener))
}
