# Host updates prototype

This host-local dashboard checks for incoming chezmoi commits, local dotfile drift, and outdated Homebrew formulae and casks. It checks at startup and hourly by default. The last result and any pending previews live in memory.

## Run on macOS

Use Go 1.24+, Node 22.12+ (or Node 20.19+), Git, Homebrew, and a chezmoi version that supports `--skip-secrets`.

```sh
cd web
npm ci
npm run build
go build -o host-updates .
cp .env.example .env
set -a
. ./.env
set +a
./host-updates
```

Open [the local dashboard](http://127.0.0.1:8780/). The default repository is `~/.local/share/chezmoi` and can be set with `-repo`. Use `-interval 30m` to change the check frequency. Press Ctrl+C to stop the prototype.

Edit `.env` for your machine. The executable reads exported environment variables and flags override them. Git ignores local environment files.

## Review and apply

- **Dotfiles** checks the configured upstream and compares the current checkout with the files on this Mac. Preview evaluates incoming commits in a temporary Git worktree and displays the filenames that would change. Apply fast-forwards to the reviewed revision and runs a conflict-checking preflight. It applies files only, excluding encrypted entries, secret templates, scripts, and externals.
- **Homebrew** refreshes metadata and lists outdated installed formulae and casks. Use **Update** on a package row to preview that package, or **Preview all upgrades** for a batch. The preview runs Homebrew’s native dry run. Homebrew may also upgrade dependencies. Casks that need interactive authorization can fail.
- Previews expire after 15 minutes. Apply rechecks the plan and requires another preview if it changed. Operations run one at a time. The dashboard does not automatically install updates.

## Tailnet access

To serve the prototype on an unused HTTPS port, start it with your actual Tailscale HTTPS origin and login, then point Serve at the loopback port. Use Serve so it supplies the authenticated identity header.

```sh
./host-updates -chezmoi "$(brew --prefix)/bin/chezmoi" \
  -origin https://YOUR-HOST.YOUR-TAILNET.ts.net:8445 \
  -tailscale-user YOUR-TAILSCALE-LOGIN
tailscale serve --bg --https=8445 http://127.0.0.1:8780
```

Remove that route with `tailscale serve --https=8445 off`. Run the service as the dotfiles user. Restrict Serve access using your tailnet policy. Local mode is intended for a trusted single-user Mac.

## Interactive terminal

The terminal is opt-in. Set `-shell /bin/zsh` and use GitHub sign-in, a private Unix socket, or an app access key with the allowed Tailscale identity. The **Terminal** link opens a login shell as the service user. Confirming a single-package update opens a terminal attached to that reviewed Homebrew command. Closing the shell ends its session. Closing the Homebrew console leaves a running upgrade on the host. The web terminal bundles FantasqueSansM Nerd Font Mono under the [SIL Open Font License](src/fonts/OFL-Fantasque.txt).

On this Mac, Serve returned HTTP 502 when proxying a private Unix socket. To use GitHub sign-in, register an OAuth app with an authorization callback of `https://YOUR-HOST.YOUR-TAILNET.ts.net:8445/auth/github/callback`. Store its credentials and the numeric GitHub account ID of the owner in a private file with mode `0600`.

```json
{ "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "ownerId": 123456 }
```

Pass `-github-auth-file /path/to/github-auth.json -shell /bin/zsh` along with the HTTPS origin and Tailscale login. GitHub sign-in checks the account ID, uses PKCE, and requests no repository permissions. App sessions expire after eight hours or when the process restarts.

For environment-based setup, copy `.env.tailscale.example` to `.env.tailscale`, fill in the placeholders, and source it after `.env` with `set -a` enabled. Then run `./host-updates` and configure Tailscale Serve as above. Keep the OAuth credentials in the private JSON file referenced by `HOST_UPDATES_GITHUB_AUTH_FILE`.

For an installation using access-key sign-in, create a key in a private directory and use a new filename.

```sh
key_dir="$HOME/Library/Application Support/Host Updates"
install -d -m 700 "$key_dir"
(umask 077; set -C; openssl rand -hex 32 > "$key_dir/access-key")
```

Pass `-access-key-file "$key_dir/access-key" -shell /bin/zsh` along with the HTTPS origin and Tailscale login. Copy the key on your Mac with `pbcopy < "$key_dir/access-key"` and paste it into the sign-in page. Sessions expire after eight hours or when the process restarts.

For a host where Serve can reach a Unix socket, use an absolute socket path in a directory owned by the service user with mode `0700`. Pass `-unix-socket /path/to/private/backend.sock -shell /bin/zsh` with the HTTPS origin and Tailscale login, and point Serve to `unix:/path/to/private/backend.sock`.

## Verification

```sh
npm run check
TEST_CHEZMOI="$(brew --prefix)/bin/chezmoi" go test ./...
```

APT, pacman, durable history, and service installation are outside this Mac prototype.
