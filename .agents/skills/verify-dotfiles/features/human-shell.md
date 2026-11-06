# Human terminal shell

A user opens a terminal and gets a login zsh with the starship prompt, zinit plugins, aliases and functions loaded after the first prompt, direnv, and no locale or plugin errors.

## Sub-features

- `human-start` starts a login shell with no errors on stderr.
- `human-prompt` shows the starship prompt.
- `human-deferred` loads aliases, functions, abbreviations and plugins through zsh-defer after the first prompt.
- `human-tools` finds direnv and starship from zinit, and mise shims.
- `human-locale` uses `en_US.UTF-8` without warnings.

## How to get to it (user POV)

- Open a terminal or SSH session whose login shell is zsh.
- Run `zsh -l` or `exec zsh` from another shell.

## Driving it with verify-dotfiles

Preconditions:

- A run from `$V launch`, and `$V doctor` exits 0.
- The host has `en_US.UTF-8` (`locale -a` lists `en_US.utf8`). On grokbot a run script generates it, and that script does not run in this harness.

- **Open a terminal.** Start an interactive login shell in the private tmux server. Run `$V pty start human`. It prints `== pty-ready-human: exit 0`. The first start can take minutes while zinit installs plugins.
- **Prompt and deferred loads.** Use the prompt. Run `$V pty run --label human-aliases 'alias | wc -l; command -v direnv starship; locale 2>&1 | head -2'`. Exit `0`. The `.screen` file shows the starship prompt line (`❯`), an alias count above `100` (`163` on grokbot at the time of writing), `.../zinit/plugins/direnv---direnv/direnv`, `.../zinit/plugins/starship---starship/starship` and `LANG=en_US.UTF-8`, with no `perl: warning` or `command not found` lines.
- **Full screen.** Save the session. Run `$V pty capture human-session`. The `.screen` file has the whole pane history.
- **Close the terminal.** Run `$V pty stop`. It prints `pty stopped`.
- **One-shot start.** Prove a clean start without a prompt. Run `$V shell --label human-start human -- 'true'` after the PTY has installed the plugins. Exit `0`, and `.stderr` is empty.

## Gotchas

- `zsh -l -i -c` exits before the first prompt, so zsh-defer never runs. A one-shot human shell shows only a few aliases (`7` on grokbot). Count aliases in the PTY.
- The first PTY start can also print plugin install output on the screen. Judge errors from a later step.
- Do not type into the PTY while a step waits. `pty run` waits for its own marker. A command that never returns times out after `VERIFY_TIMEOUT` seconds and saves the screen.
- zsh-abbr expands abbreviations when you type a space. If a typed command starts with an abbreviation, the screen shows the expanded text.
- Human mode uses the gh-r direnv download. If an agent shell installed direnv first, both modes must use the same load (see the agent feature).
