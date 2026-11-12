#!/usr/bin/env bash
# Checks that chezmoi/dot_zshenv gives agent shells the project's tool versions.
# Agent shells are not interactive, so the `mise activate` cd hook never runs.
# Run: tests/agent-mise-shims.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

mise_bin=$(command -v mise) || { echo "FAIL - mise is not installed"; exit 1; }
installs=${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/ruby
global=$(cd "$HOME" && "$mise_bin" current ruby)
project=$(ls "$installs" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | grep -vxF "$global" | head -1)
[[ -n $global && -n $project ]] || { echo "FAIL - need two installed Ruby versions"; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/zdot" "$tmp/proj"
cp chezmoi/dot_zshenv "$tmp/zdot/.zshenv"
echo "ruby $project" > "$tmp/proj/.tool-versions"

# PATH like the one an agent gets from its parent process: the global Ruby is
# already on it, and mise's cd hook will not run again.
base_path="$(dirname "$mise_bin"):$installs/$global/bin:/usr/bin:/bin"
stale=(__MISE_ORIG_PATH="/usr/bin:/bin" __MISE_SESSION=stale MISE_SHELL=zsh)
[[ -n ${__MISE_DIFF:-} ]] && stale+=(__MISE_DIFF="$__MISE_DIFF")

# Starts zsh in $HOME like an agent does, then changes into the project.
agent_ruby() {
  env -i HOME="$HOME" USER="${USER:-}" PATH="$base_path" ZDOTDIR="$tmp/zdot" "$@" \
    zsh -c "cd '$tmp/proj' && ruby -e 'print RUBY_VERSION'" 2>&1
}

eq "Codex shell uses the project Ruby" "$(agent_ruby CODEX_THREAD_ID=t)" "$project"
eq "Claude Code shell uses the project Ruby" "$(agent_ruby CLAUDECODE=1)" "$project"
eq "AI_AGENT shell uses the project Ruby" "$(agent_ruby AI_AGENT=x)" "$project"
eq "stale mise variables do not change the result" \
  "$(agent_ruby CODEX_THREAD_ID=t "${stale[@]}")" "$project"
eq "non-agent shell is not changed" "$(agent_ruby)" "$global"

# A daemon (for example a pitchfork supervisor) keeps the agent shell's PATH
# and later starts a process in the project directory, without zsh.
daemon_path=$(env -i HOME="$HOME" PATH="$base_path" ZDOTDIR="$tmp/zdot" CODEX_THREAD_ID=t \
  zsh -c 'print -r -- $PATH')
eq "daemon started from an agent shell uses the project Ruby" \
  "$(env -i HOME="$HOME" PATH="$daemon_path" sh -c "cd '$tmp/proj' && ruby -e 'print RUBY_VERSION'" 2>&1)" \
  "$project"

exit $fail
