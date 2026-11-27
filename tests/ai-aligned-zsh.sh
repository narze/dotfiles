#!/usr/bin/env bash
# Checks that chezmoi/dot_zshenv.tmpl gives agent shells bash-like word
# splitting and globbing (ai-aligned-zsh), and leaves human shells as they are.
# Agents write bash, but run it through the login shell: `zsh -c` or `zsh -lc`.
# Run: tests/ai-aligned-zsh.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

command -v zsh >/dev/null || { echo "FAIL - zsh is not installed"; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.local/bin"
chezmoi --source chezmoi execute-template < chezmoi/dot_zshenv.tmpl > "$tmp/home/.zshenv" || exit 1
hook=chezmoi/dot_local/bin/executable_ai-aligned-zsh
[[ -f $hook ]] && cp "$hook" "$tmp/home/.local/bin/ai-aligned-zsh"

# The command that failed in an agent session: in zsh, $B stays one argument.
# shellcheck disable=SC2016 # zsh expands it, not this script
cmd='B="-c user.name=x -c user.email=y"; V="a b"; for v in $V; do printf "<%s>" "$v"; done; echo " $(git $B config user.name 2>&1 | head -1)"'
split='<a><b> x'
nosplit='<a b> unknown option: -c user.name=x -c user.email=y'

run() {
  env -i HOME="$tmp/home" PATH="/usr/bin:/bin" "$@" 2>&1 | head -1
}

eq "Claude Code shell splits like bash" "$(run CLAUDECODE=1 zsh -c "$cmd")" "$split"
eq "Codex login shell splits like bash" "$(run CODEX_THREAD_ID=t zsh -lc "$cmd")" "$split"
eq "OpenCode shell splits like bash" "$(run OPENCODE=1 zsh -c "$cmd")" "$split"
eq "AI_AGENT shell splits like bash" "$(run AI_AGENT=x zsh -c "$cmd")" "$split"
eq "Cursor agent shell splits like bash" "$(run CURSOR_AGENT=1 zsh -c "$cmd")" "$split"
eq "agent glob with no match stays literal" \
  "$(run CLAUDECODE=1 zsh -c 'cd /; echo --include=*.nomatch')" "--include=*.nomatch"
eq "agent echo ==== prints it" "$(run CLAUDECODE=1 zsh -c 'echo ====')" "===="
eq "AI_ALIGNED_ZSH=off turns it off" "$(run AI_ALIGNED_ZSH=off CLAUDECODE=1 zsh -c "$cmd")" "$nosplit"
eq "non-agent shell is not changed" "$(run zsh -c "$cmd")" "$nosplit"
# Without a terminal (CI), zsh -i warns on stderr, so only stdout is compared.
eq "interactive agent shell is not changed" \
  "$(env -i HOME="$tmp/home" PATH="/usr/bin:/bin" CLAUDECODE=1 zsh -i -c "$cmd" 2>/dev/null | head -1)" \
  "$nosplit"

exit $fail
