---
name: chezmoi-reconcile
description: Reconcile drift between the local machine and the chezmoi dotfiles repo, deciding per file whether the machine edit or the repo source wins. Use whenever the user asks to run `chezmoi diff`, resolve chezmoi conflicts, sync or update dotfiles, check why `chezmoi apply` wants to change things, or fix drift after editing a managed config. Also trigger on /chezmoi-reconcile.
---

# Reconcile chezmoi dotfiles

## Overview

Dotfiles live in the `chezmoi/` source directory (set by `.chezmoiroot`), not the repo root. The real files under `$HOME` are the **destination**; the repo files are the **source/target**. Drift is normal: apps regenerate their own config, and the user edits managed files by hand.

This skill walks the drift file by file, asks the user which side wins, applies the choice, and verifies a clean result. Never run a blanket `chezmoi apply` before resolving drift: it silently overwrites local edits, which is exactly what the user is trying to decide about.

## Workflow

### 1. Inventory the drift

Run both commands:

```bash
chezmoi status
chezmoi diff
```

Read `chezmoi diff` carefully. In each hunk, `-` lines exist only on the machine and `+` lines exist only in the repo source. So `-` marks a local edit that `apply` would delete, and `+` marks repo content that `apply` would write.

Read `chezmoi status` as two status columns. `MM` means the file differs on both sides (a real conflict to resolve). `R` marks run scripts, which are handled separately (step 4).

For each conflicting managed file, find its source path:

```bash
chezmoi source-path ~/.config/example/config.toml
```

### 2. Present every drift as a choice

Do not decide for the user. Present one row per file with the machine-side content and the repo-side content side by side, then ask which wins. Group independent files into a single set of questions so the user can answer them together, but keep each file its own decision.

Each file resolves one of three ways:

| Choice | Command | Effect |
|---|---|---|
| Keep local, update repo | `chezmoi add <target>` | Machine file becomes the source; commit later |
| Take repo, overwrite local | `chezmoi apply --force <target>` | Machine file is reverted to the source |
| Skip | none | Leave it diverged for now |

### 3. Apply the choices

`chezmoi apply` only touches a destination file when it differs from the source, so it is safe to run specific targets.

- **Keep local:** `chezmoi add ~/.config/example/config.toml`
- **Take repo:** `chezmoi apply --force ~/.config/example/config.toml`

Two non-interactive gotchas cause `chezmoi: could not open a new TTY: open /dev/tty: device not configured` and must be avoided in an agent shell:

- `chezmoi apply` prompts "has changed since chezmoi last wrote it?" for every modified destination. Pass `--force` to accept the overwrite the user already approved.
- `chezmoi add` on an **encrypted** file prompts "would remove encrypted attribute". Pass `--encrypt` to preserve encryption, e.g. `chezmoi add --encrypt ~/.ssh/config`. Verify the source path is unchanged with `chezmoi source-path` afterwards.

### 4. Run pending scripts

New or changed run scripts show as `R` in `chezmoi status` and appear in `chezmoi diff` as new files. `run_*` scripts run on every apply, so they always show `R`; that is expected and not drift. Run them with:

```bash
chezmoi apply --force
```

An "elsewhere" run script runs all other scripts in `scripts/<os>/`. Confirm it exits 0.

## Verify and finish

```bash
chezmoi diff          # should show only run_ scripts, which always appear
chezmoi status        # conflicts gone; only run-script R lines remain
git status --short    # repo source files that "keep local" updated
```

The `chezmoi: warning: config file template has changed, run chezmoi init to regenerate config file` warning is pre-existing; ignore it unless the user asks about it.

Only "keep local" files change the repo. Commit when the user asks, in small commits, with a plain dash (never an em dash). Report which files went each way, which scripts ran, and the final git status.
