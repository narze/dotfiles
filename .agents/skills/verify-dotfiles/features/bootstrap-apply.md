# Bootstrap and apply

A user runs `chezmoi init` and `chezmoi apply` (directly, through `install.sh`, or through `make apply`) and gets the managed files in `$HOME` for their OS, host and Debian profile, with no drift left.

## Sub-features

- `apply-init` renders `chezmoi/.chezmoi.yaml.tmpl` into a config, including the Debian profile prompt.
- `apply-files` writes the managed files and `chezmoi status` is clean after it.
- `apply-gating` skips files that `.chezmoiignore` excludes for this OS, host or profile.
- `apply-idempotent` makes a second apply change nothing.
- `apply-profile` selects the Debian profile scripts (`.chezmoiscripts/debian/<profile>/`).

## How to get to it (user POV)

- Run `chezmoi init` then `chezmoi apply` from an existing checkout.
- Run `./install.sh` from the repo root (`chezmoi init --apply --source=<repo> -k -x encrypted`).
- Run `make apply` (a wrapper for `chezmoi apply`) or `make bootstrap` (`chezmoi init`).
- Run `ASK=1 chezmoi init` to answer the name, email and host prompts.

## Driving it with verify-dotfiles

Preconditions:

- No run is needed before this recipe. `$V launch` is the entry point.
- The working tree has the change under test.

- **Init and apply.** Make a fresh HOME. Run `$V launch`. Evidence `01-init`, `02-apply` and `03-status` all have exit `0`, and `03-status.stdout` is empty.
- **Profile.** Read the chosen profile. Run `$V chezmoi --label data -- data --format json` and read `.debian_profile` in the stdout. On a Debian host it equals the `--profile` value (default: this machine's profile).
- **Profile scripts.** List the scripts for the profile. Run `$V chezmoi --label scripts -- managed --include=scripts`. Run `grep debian` on its `.stdout`. It lists the base `debian/` scripts and only `debian/<profile>/` scripts (on grokbot: `debian/ai-agent/50_packages.sh`). Scripts of other profiles (`debian/homelab/`) are absent.
- **Gating.** Check an excluded target. Run `$V chezmoi --label managed -- managed --include=files,symlinks`. On Linux, macOS-only targets (`.aerospace.toml`, `.hammerspoon`, `.config/karabiner`) are absent. On grokbot, `laptop` is absent, and `$V shell --label laptop agent-tool -- 'ls -ld ~/laptop'` exits `2`. On other hosts, `laptop` is listed, and the same command shows a symlink.
- **Rendered file.** Read a host-gated file. Run `$V chezmoi --label zshenv -- cat .zshenv`. On grokbot, the output starts with the `# grokbot:` PATH block and has `mise activate zsh`. On other hosts, it starts with `# Activate mise`.
- **Idempotent.** Apply again. Run `$V chezmoi --label apply-2 -- apply -x scripts,encrypted,externals` and then `$V chezmoi --label status-2 -- status -x scripts,encrypted,externals`. Both exit `0`, and the status stdout is empty.

## Gotchas

- `install.sh` and plain `chezmoi init --apply` also run the run scripts (apt, `chsh`, installers). This harness excludes them, so a script change stays unverified here.
- Without `-x encrypted`, apply stops at the first encrypted file with `gpg: decryption failed: Bad session key`.
- On Debian, `promptStringOnce` asks for the profile. Without a TTY and without `--promptString`, init fails. `$V launch` passes the answer.
- `chezmoi managed --include=scripts` also lists OS-gated scripts (`darwin_*`, `codespaces_*`) on Linux. They are templates that render empty, so chezmoi skips them at apply time. Their presence in the list does not mean that they run.
- On grokbot, the generated config sets `sourceDir` to `<HOME>/laptop`. In a run HOME that folder does not exist, so the helper always passes `--source <repo>`. A bare `chezmoi` call with `HOME=<run home>` fails.
- `chezmoi: warning: config file template has changed` on the real machine means its config is older than the template. It does not affect a run, which always runs init.
