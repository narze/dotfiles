#!/usr/bin/env bash
# The ; <-> : override on physical P must also apply while Alt is held, otherwise
# Hyprland sees ALT+SHIFT+colon for the key typed as ";" and ALT+; binds never match.
# Run: tests/kanata-alt-overrides.sh
set -u
cfg=${1:-$HOME/.config/kanata/kanata.kbd}
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

kanata --cfg "$cfg" --check >/dev/null 2>&1 && ok "config is valid" || bad "config is valid"
grep -qE '^\s*\(lalt p\)\s+\(lalt lsft p\)' "$cfg" && ok "Alt+P -> Alt+Shift+P override" || bad "Alt+P -> Alt+Shift+P override"
grep -qE '^\s*\(lalt lsft p\)\s+\(lalt p\)' "$cfg" && ok "Alt+Shift+P -> Alt+P override" || bad "Alt+Shift+P -> Alt+P override"
exit $fail
