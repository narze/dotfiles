# Agent shells

When Claude Code, T3 Code, Cursor or OpenCode start zsh (`CLAUDECODE`, `CURSOR_AGENT` or `OPENCODE` is set), the dotfiles load mise and the plugins at once and skip starship and deferred loads, so agent commands find their tools and print no shell errors.

## Sub-features

- `agent-tool-clean` makes the Bash tool form (`zsh -l -c`) print nothing extra on stderr.
- `agent-mise` activates mise for zsh, also when `SHELL=/bin/bash`.
- `agent-path` puts mise, `~/.local/bin` and (on grokbot) `~/.opencode/bin` on PATH.
- `agent-plugins` loads zsh-abbr, syntax highlighting, history search and autosuggestions without zsh-defer.
- `agent-direnv` installs and finds the direnv binary.
- `agent-aliases` loads aliases and functions without a prompt.

## How to get to it (user POV)

- An agent runs a command through its Bash tool while the login shell is zsh (Claude Code and T3 Code run `zsh -c -l <command>` with `SHELL=/bin/bash`).
- An agent opens an interactive zsh (`zsh -i`), for example in a terminal pane that it controls.
- Cursor (`CURSOR_AGENT`) and OpenCode (`OPENCODE`) take the same code path as `CLAUDECODE`.

## Driving it with verify-dotfiles

Preconditions:

- A run from `$V launch`, and `$V doctor` exits 0.
- To prove a first-install bug (for example, how direnv installs), the first interactive shell of the run must be an `agent` shell. Do not start a `human` shell or PTY before it.

- **Bash tool form.** Run a command the way Claude Code does. Run `$V shell agent-tool -- 'echo $SHELL; command -v mise opencode; echo $PATH'`. Exit `0`, stdout shows `/bin/bash`, `mise`, and on grokbot `<run home>/.opencode/bin/opencode`. PATH starts with `<run home>/.local/share/mise/shims`. `.stderr` is empty.
- **First interactive agent shell.** Start the shell that installs zinit. Run `$V shell agent -- 'command -v direnv opencode; alias | wc -l; type zsh-defer | head -1'`. Exit `0`. Stdout lists `<run home>/.local/share/zinit/plugins/direnv---direnv/direnv` (a binary, not the source repo), the opencode path, an alias count above `100` (`163` on grokbot at the time of writing), and on grokbot `zsh-defer is a shell function from .../zinit.zsh` (the agent shim). Stderr has only zinit install progress. Stdout has install progress before these lines, so read them with `grep -aE '^(/.*/(direnv|opencode)|[0-9]+|zsh-defer is .*)$' <evidence>/<nn>-agent.stdout`.
- **Second interactive agent shell.** Prove that there are no errors. Run `$V shell --label agent-2nd agent -- 'true'`. Exit `0`, and `.stderr` is empty.
- **Second Bash tool call.** Run `$V shell --label agent-tool-2nd agent-tool -- 'true'`. Exit `0`, and `.stderr` and `.stdout` are empty.
- **Rendered sources.** Show the agent code that ran. Run `$V chezmoi --label zinit -- cat .config/zsh/plugin-managers/zinit.zsh` and `$V chezmoi --label zshenv -- cat .zshenv`. The agent block and the mise line match what the shells did.

## Gotchas

- The first interactive shell of a run clones zinit and every plugin. It can take from 1 to 7 minutes and writes progress to stdout and stderr (stdout can be over 600 KB). Check its result lines with `grep -a` on the `.stdout` file, and prove "no errors" on a later shell.
- Interactive shells print `Time used for zinit: <n> ms` on stdout. Do not count it as an error.
- `zsh -l -c` (agent-tool) does not read `~/.zshrc`. Only `~/.zshenv` (and `.zprofile`/`.zlogin` if present) runs, so aliases and plugins are absent there by design.
- `mise activate` without a shell name prints code for `$SHELL`. With `SHELL=/bin/bash` that is bash code, which fails in zsh with `no such hash table element` and `complete: command not found`.
- If a shell starts in a folder under the real HOME, mise reads the real `~/.config/mise/config.toml` as a project config and reports that it is not trusted. The helper starts every shell in the run HOME.
- A stale `zinit/plugins/direnv---direnv` folder from an old bug stays broken until it is deleted. A new run HOME never has it.
