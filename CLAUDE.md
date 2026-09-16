# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Supports macOS, Debian Linux, Ubuntu, GitHub Codespaces, and Windows.

**Chezmoi source root:** the `chezmoi/` subdirectory (set in `.chezmoiroot`). All managed dotfiles live there — not the repo root.

## Common Commands

```bash
# Apply dotfiles to the current machine
chezmoi apply

# Preview what would change
chezmoi diff

# Re-run initialization (e.g. to change Debian profile)
chezmoi init

# Initialize with prompts for name/hostname/email/profile
ASK=1 chezmoi init

# Re-run once scripts (e.g. after testing a new install script)
# Delete the script hash from chezmoi's state to force re-run:
chezmoi state delete-bucket --bucket=scriptState

# Edit a managed file and apply in one step
chezmoi edit ~/.config/starship.toml --apply

# Add a new file to be managed
chezmoi add ~/.config/somefile
```

Make targets (thin wrappers):
```bash
make apply      # chezmoi apply
make bootstrap  # chezmoi init
make dotfiles   # chezmoi apply -i files (files only, no scripts)
make macos      # run macOS preference scripts
```

## Architecture

### Template System

Files ending in `.tmpl` are Go templates processed by chezmoi. Template data comes from `.chezmoi.yaml.tmpl`, which defines:
- `{{ .chezmoi.os }}` — `darwin`, `linux`, `windows`
- `{{ .chezmoi.osRelease.id }}` — `debian`, `ubuntu` (Linux only)
- `{{ .debian_profile }}` — active Debian profile
- `{{ .hostname }}`, `{{ .name }}`, `{{ .email }}`, `{{ .github_user }}`
- `{{ .flags.delta_is_not_installed }}`, `{{ .flags.gh_is_installed }}`, `{{ .flags.is_codespace }}`

### OS-Conditional File Ignoring

`.chezmoiignore` uses templates to exclude OS-specific files. macOS-only configs (karabiner, sketchybar, yabai, aerospace, hammerspoon) are ignored on Linux. Linux-only configs are ignored on macOS.

### Debian Profile System

On Debian, users choose a profile at `chezmoi init` time:
- **`minimal`** — zsh, git, curl, mise
- **`homelab`** — extends minimal with homelab tools
- **`ai-agent`** — extends minimal with Claude Code CLI and OpenCode CLI

Profiles live in `chezmoi/.chezmoiscripts/debian/<profile>/`. The active profile's scripts run; others are ignored via `.chezmoiignore`. Adding a new profile = create a new directory there.

### Script Execution Order

Scripts in `chezmoi/.chezmoiscripts/` follow chezmoi's naming convention:
- `run_once_before_*` — run once, before file application
- `run_once_after_*` — run once, after file application
- `run_before_*` / `run_after_*` — run every `chezmoi apply`

The master dispatcher `run_after_00-run-scripts-by-os.sh.tmpl` routes to `scripts/darwin/`, `scripts/linux-ubuntu/`, or `scripts/linux-debian/<profile>/` based on OS.

### Encryption

Sensitive files (`.asc` suffix) use GPG symmetric encryption. The passphrase is set via `SETPASS=1 chezmoi init`. When installing fresh without a GPG key, pass `-x encrypted` to skip encrypted files.

Attribute prefixes come before `dot_`/`private_` in a fixed order - for files it is `encrypted_`, `private_`, `readonly_`, `empty_`, `executable_`, `dot_` (see [source state attributes](https://www.chezmoi.io/reference/source-state-attributes/)). So an encrypted script on PATH is `bin/encrypted_executable_<name>.asc`, which lands as `~/bin/<name>` mode 755. Edit an encrypted file with `chezmoi edit ~/bin/<name>` (never the `.asc` directly); `chezmoi encrypt`/`chezmoi decrypt` read the same config for one-off conversions.

### User Scripts

`chezmoi/bin/` maps to `~/bin`, which `dot_zshrc` puts on PATH. Personal command-line tools live there.

Keep them plaintext (`bin/executable_<name>`) so they stay lintable and reviewable in diffs; encrypt only a script that cannot work without an embedded secret, and prefer moving that secret into a separate encrypted file the script reads at run time. Scripts here should pass `shellcheck` at its default severity.

### External Dependencies

`chezmoi/.chezmoiexternal.toml` manages downloaded artifacts (tmux config, zellij WASM plugins, Hammerspoon spoons). These are fetched automatically on `chezmoi apply`.

## Key Files

| File | Purpose |
|------|---------|
| `chezmoi/.chezmoi.yaml.tmpl` | Template variables and Debian profile prompt |
| `chezmoi/.chezmoiignore` | Conditional per-OS file exclusions |
| `chezmoi/.chezmoiexternal.toml` | External downloads (plugins, configs) |
| `chezmoi/private_dot_config/starship.toml` | Starship prompt (uses `[os]` module for auto OS icon) |
| `chezmoi/dot_gitconfig.tmpl` | Git config (delta pager, gh credential helper, opencode as git worktree AI) |
| `chezmoi/dot_zshenv` | Activates mise for Claude Code / Cursor / OpenCode agents |
| `chezmoi/bin/executable_evp-preview` | `evp-preview` - boots an eventpop PR/branch in its own worktree and port slot against the shared dev database |

## Shell Setup

Zsh loads plugins via one of three plugin managers (zim, zinit, or zpm) — controlled by which is active in `~/.config/zsh/plugin-managers/`. Config pieces load from `~/.config/zsh/config/` in order: `00_aliases`, `10_options`, `20_functions`.
