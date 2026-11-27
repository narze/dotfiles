#!/usr/bin/env bash
# Checks that the zsh alias files load in the order .zshrc uses, without errors.
# A parse error in a sourced file stops the rest of that file, so one bad line
# can drop every alias after it.
# Run: tests/zsh-aliases.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

command -v zsh >/dev/null || { echo "FAIL - zsh is not installed"; exit 1; }
config=chezmoi/private_dot_config/zsh/config

# Interactive, so aliases expand while the files are read, as in a terminal.
load() {
  env -i HOME=/nonexistent PATH=/usr/bin:/bin TERM=dumb zsh -f -i -c \
    "source '$config/00_omarchy.zsh'; source '$config/00_aliases.zsh'; $1" 2>&1
}

eq "alias files load without errors" "$(load ':')" ""
eq "aliases at the end of 00_aliases.zsh are defined" "$(load 'alias kx')" "kx='kubectl exec'"
eq "gcam is the 00_aliases.zsh function, not the Omarchy alias" \
  "$(load 'whence -w gcam')" "gcam: function"

exit $fail
