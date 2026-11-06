---
name: verify-dotfiles
description: Prove what these chezmoi dotfiles do for a user by applying them into a disposable HOME and driving real zsh shells (human terminal, interactive agent shell, Claude Code Bash tool form) and git, with saved evidence. Use after changing anything under chezmoi/ (templates, .chezmoiignore, zsh/zinit config, gitconfig, host gating), when a shell prints errors or misses a tool, or on /verify-dotfiles.
---

# Verify the dotfiles

The "app" is this chezmoi repo. A user touches it in three ways: `chezmoi init/apply` writes files into `$HOME`, then a zsh shell starts (terminal login or agent shell), then tools such as git read the written config. The chezmoi source is `chezmoi/` (see `.chezmoiroot`), not the repo root.

All driving goes through one helper. It applies the repo into a disposable HOME, runs each shell from a clean environment, and saves the command, stdout, stderr and exit code for every step:

```bash
V=.agents/skills/verify-dotfiles/scripts/verify-dotfiles   # from the repo root
$V help
```

Never verify against the real `$HOME`. `chezmoi apply` there overwrites the user's files and runs install scripts. To check the real machine, use the read-only host checks instead, for example `tests/grokbot.sh` on grokbot.

## Launch

```bash
$V launch                     # same Debian profile as this machine
$V launch --profile minimal   # another Debian profile
$V launch --externals         # also download .tmux.conf and zellij plugins (network)
```

What it does:

1. It makes `$VERIFY_DOTFILES_ROOT/runs/<run-id>/home` (default root `${TMPDIR:-/tmp}/verify-dotfiles`) with a marker file `.verify-dotfiles-run`.
2. It links `mise`, `chezmoi` and `~/.opencode` from the real HOME into the run HOME. This is verification scaffolding: the run scripts that install them are excluded (see Isolation).
3. It runs `chezmoi init` (with the profile answer), then `chezmoi apply --force -x scripts,encrypted,externals`, then `chezmoi status`. Every chezmoi call uses `--source <repo>` and a clean `env -i` environment.

Ready means: launch prints `Ready: files applied and chezmoi status is clean.` with `RUN_ID`, `RUN_HOME` and `EVIDENCE`. Launch fails and names the evidence file if init or apply fails, or if status is not clean.

zinit is not installed yet at that point. The first interactive shell clones zinit and every plugin. On grokbot that took about 7 minutes for the first agent shell and 15 seconds for the first human shell after it. The helper allows 900 seconds per step (`VERIFY_TIMEOUT` changes it).

The newest launch is the selected run. Use `$V --run <run-id> <command>` to drive an older run. Each run has its own HOME and its own tmux socket, so two runs can exist side by side.

## Doctor

Run this first when something looks wrong, and before you drive a run you did not launch in this session:

```bash
$V doctor
```

It is read-only. It prints `key=value` lines and exits non-zero when the run is not worth driving:

- `run_home`, `evidence`, and `launch.*` (repo, HEAD at launch, profile, scaffolding links).
- `repo_head_now` and `repo_dirty`. The run reads the live working tree, so after you edit `chezmoi/`, run `$V chezmoi -- apply --force -x scripts,encrypted,externals` or launch a new run.
- `host`, `os`, `chezmoi` version, `debian_profile`.
- `applied=yes` only when `chezmoi status` shows no drift.
- `zinit=installed|not-yet`, and `pty=running|stopped`.

## Drive

### One-shot shells

```bash
$V shell <mode> -- '<zsh command>'
$V shell --label <name> <mode> -- '<zsh command>'
```

| Mode | Command line | Environment | Real-world equivalent |
| --- | --- | --- | --- |
| `human` | `zsh -l -i -c` | `SHELL=<zsh>` | A terminal login on the machine |
| `agent` | `zsh -i -c` | `SHELL=/bin/bash`, `CLAUDECODE=1` | An interactive shell started by an agent |
| `agent-tool` | `zsh -l -c` | `SHELL=/bin/bash`, `CLAUDECODE=1` | The Claude Code / T3 Code Bash tool when the login shell is zsh |

Every shell starts in the run HOME with `env -i`, `HOME=<run home>` and `PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`. Nothing from the calling shell leaks in.

### Interactive terminal (PTY)

Use the PTY for behavior that needs a prompt: zsh-defer loads (aliases and functions in human shells), the starship prompt, and keys.

```bash
$V pty start human            # or: agent. Waits for the first prompt.
$V pty run --label <name> '<command>'
$V pty capture <name>         # full pane history
$V pty stop
```

`pty run` types the command plus a marker `printf`, presses Enter, waits for `__VD_DONE_<n>_<exit>__`, and saves the screen. It runs in a private tmux server (`tmux -L verify-dotfiles-<run-id>`), so it never touches the user's tmux sessions.

### chezmoi against the run HOME

```bash
$V chezmoi -- managed --include=symlinks
$V chezmoi -- cat .zshenv            # rendered target; paths are relative to the run HOME
$V chezmoi -- data --format json
```

### Feature map

`features/README.md` lists each user-facing feature with its entry points, exact drive commands and the end state that proves it. Read it before you drive. When you change a feature, drive every entry point that its file lists.

## Evidence

Every `launch`, `shell`, `chezmoi` and `pty run` step writes `$EVIDENCE/<nn>-<label>.*`:

- `.cmd`: the exact command line
- `.stdout`, `.stderr`, `.exit`: for `shell` and `chezmoi` steps. The helper prints only the last 40 lines of each (`VERIFY_PRINT_LINES` changes it). The files keep everything.
- `.screen`, `.exit`: for `pty run` steps, which save the full pane history

Proof standards:

- Drive the real user path: `chezmoi apply` and a real zsh startup. Do not source single files or call helper functions directly.
- Capture the action and the resulting state. For a shell, that means the command, stdout, stderr and exit code, not only "it printed X".
- Check side effects next to visible output: the file that chezmoi wrote (`$V chezmoi -- cat <target>` or the file under the run HOME), the binary that zinit installed, and the git config value that git actually resolves.
- An empty `.stderr` file is the proof of "no errors". A first-run zinit install writes progress to stderr, so prove "no errors" on a second shell of the same mode.
- Report a skipped entry point as skipped, with the reason. Do not report it as verified through another path.

`$V paths` prints the evidence folder. Evidence is outside the run folder, so cleanup keeps it.

## Cleanup

```bash
$V cleanup
```

It stops the run's tmux server, stops processes whose command line contains the run HOME, deletes `runs/<run-id>` (only after the marker and the path checks pass) and prints `evidence kept: <path>`. It never kills by process name and never touches the real HOME. Run it after every run, including failed attempts. To remove old evidence, delete `$VERIFY_DOTFILES_ROOT/evidence/<run-id>` by hand.

## Isolation and limits

- Excluded: run scripts (`.chezmoiscripts`: apt, `chsh`, mise/gh/delta/opencode installers, locale generation, macOS defaults). They change the whole machine, so this harness does not run them. Verify a script change on a disposable machine or VM, or read it and say that it is unverified.
- Excluded: encrypted files (`encrypted_*.asc`). Without the GPG passphrase, `chezmoi apply` stops at the first one with `gpg: decryption failed: Bad session key`. Always keep `-x encrypted` unless the user sets the passphrase.
- Shared with the machine: system packages (zsh, git, delta, gh, tmux), the network that zinit uses, and the scaffolding links to the real `mise`, `chezmoi` and `~/.opencode`. A tool that comes from a run script on a fresh machine is found here only because of these links.
- Host gating uses the real hostname (`.chezmoi.hostname`) and OS. A run on grokbot proves grokbot output only. To prove that other hosts are unchanged, render the template with the host test changed and compare the output with `git show <base>:<file>` rendered the same way.

## Helpers

- `scripts/verify-dotfiles`: the only helper. It is executable. `$V help` prints every command, and the sections above show each invocation.
- `tests/grokbot.sh` (repo root): read-only checks of the real HOME on grokbot. Run it after `chezmoi apply` on that machine.
