# Git config

After apply, git uses the user's identity, the delta pager when delta is installed, the gh credential helper for GitHub, the ghq root and an optional `~/.gitconfig.local` include.

## Sub-features

- `git-identity` sets `user.name` and `user.email` from the chezmoi data.
- `git-pager` uses delta as the pager and interactive diff filter when delta is installed, and leaves them commented out when it is not.
- `git-credential` uses `gh auth git-credential` for github.com and gist.github.com.
- `git-include` includes `~/.gitconfig.local` for host-only settings.
- `git-ghq` sets the ghq root to `~/Code`.

## How to get to it (user POV)

- Run any git command after `chezmoi apply` (`git log -p`, `git push` to GitHub, `ghq get`).
- Run `ASK=1 chezmoi init` to change the name and email, then apply.

## Driving it with verify-dotfiles

Preconditions:

- A run from `$V launch`, and `$V doctor` exits 0.
- Note whether `delta` is installed on the host (`command -v delta`). The config template checks it at init time.

- **Resolved values.** Ask git what it uses. Run `$V shell --label git human -- 'git var GIT_PAGER; git config --get user.email; git config --get-all credential.https://github.com.helper; git config --get ghq.root; git config --show-origin --get include.path'`. Exit `0`. Stdout shows `delta` (or `less` when delta is absent), the email from `chezmoi data`, an empty line then `!gh auth git-credential`, `~/Code`, and `file:<run home>/.gitconfig` with `~/.gitconfig.local`.
- **Rendered file.** Show the source of those values. Run `$V chezmoi --label gitconfig -- cat .gitconfig`. It has `pager = delta` uncommented only when delta is installed.
- **Local include.** Add a host-only value. Run `$V shell --label git-local agent-tool -- 'git config --file ~/.gitconfig.local user.email local@example.invalid && git config --get user.email'`. Stdout is `local@example.invalid`, because the include comes after `[user]`. Cleanup deletes the file with the run HOME.

## Gotchas

- `.flags.delta_is_not_installed` is computed at `chezmoi init`. If delta is installed after init, the pager stays commented out until init runs again. A run always runs init, so a run can disagree with an older real config.
- The empty `helper =` line first clears helpers from system config. `--get-all` shows it as an empty line. That is expected.
- The identity in the repo is the repo owner's. `ASK=1` changes it only on a machine where a person answers the prompts.
- `git var GIT_PAGER` resolves the pager without a TTY. This recipe proves the configured pager, not delta's rendering. Seeing delta render a diff needs a git repo in the run HOME and the PTY.
