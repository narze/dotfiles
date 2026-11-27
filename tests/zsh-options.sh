#!/usr/bin/env bash
# Checks the interactive zsh options in chezmoi/private_dot_config/zsh/config/10_options.zsh.
# Run: tests/zsh-options.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

command -v zsh >/dev/null || { echo "FAIL - zsh is not installed"; exit 1; }
options=chezmoi/private_dot_config/zsh/config/10_options.zsh

# An interactive zsh that reads typed lines from stdin, like a terminal.
typed() {
  printf '%s\n' "source '$options'" "$1" exit |
    env -i HOME=/nonexistent PATH=/usr/bin:/bin TERM=dumb PS1= zsh -f -i 2>&1 |
    tr -d '\r' | grep -o 'RESULT:.*'
}

eq "interactive shell treats # as a comment" "$(typed 'echo RESULT:a # b')" "RESULT:a"

exit $fail
