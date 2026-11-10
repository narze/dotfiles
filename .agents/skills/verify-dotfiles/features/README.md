# Dotfiles verification map

This folder is the maintained source for verifying what these dotfiles do for a user. Read this index before you drive a run, then use the matching feature file as the recipe. `$V` is `.agents/skills/verify-dotfiles/scripts/verify-dotfiles`, run from the repo root.

## Baseline preconditions

- A run made by `$V launch` in this session, and `$V doctor` exits 0 with `applied=yes`.
- The run uses the live working tree. After an edit under `chezmoi/`, re-apply with `$V chezmoi -- apply --force -x scripts,encrypted,externals` or launch a new run.
- Network access to GitHub for the first interactive shell (zinit clones plugins and downloads release binaries).
- Never drive a run HOME that this verification did not launch, and never drive the real `$HOME`.

## Driving conventions

- Start each recipe from the baseline. A recipe that needs a pristine zinit (no plugins yet) needs a new launch.
- Use the three shell modes exactly: `human` (`zsh -l -i -c`), `agent` (`zsh -i -c`, `CLAUDECODE=1`), `agent-tool` (`zsh -l -c`, `CLAUDECODE=1`). Agent modes set `SHELL=/bin/bash`, as Claude Code and T3 Code do on grokbot.
- Use `$V pty` for anything that needs a prompt (deferred loads, the prompt itself).
- Treat each command as literal. Use single quotes around the zsh command so the calling shell does not expand `$PATH` or `~`.
- Give paths for `$V chezmoi` relative to the run HOME (for example `.zshenv`). `~` would expand to the real HOME in the calling shell.

## Proof and skip reporting

- Shell proof is the `.cmd`, `.stdout`, `.stderr` and `.exit` files of the step.
- "No errors" proof is an empty `.stderr` from a shell that is not the first interactive shell of the run.
- File proof is the rendered target from the run HOME, next to the shell behavior that uses it.
- Record the feature file and the entry point with each artifact you report.
- Report an entry point that you could not reach with the command you tried and the unmet precondition.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph about the user-visible behavior. It then has exactly four H2 sections in this order:

1. `Sub-features`: short IDs, one line each.
2. `How to get to it (user POV)`: every user entry point.
3. `Driving it with verify-dotfiles`: starts with `Preconditions:`, then labeled bullets that pair a user action with an exact command and an observable result.
4. `Gotchas`: traps that waste or invalidate a run.

## Features

- [Bootstrap and apply](./bootstrap-apply.md): `chezmoi init`/`apply` into a fresh HOME, Debian profile choice, OS and host gating, clean status.
- [Agent shells](./agent-shell.md): zsh started by Claude Code, T3 Code, Cursor or OpenCode, both the Bash tool form and interactive shells.
- [Human terminal shell](./human-shell.md): login zsh with zinit plugins, starship prompt, deferred aliases, direnv and locale.
- [Git config](./git-config.md): identity, delta pager, gh credential helper, ghq root and the local include.
