#!/usr/bin/env bash
# Checks that ALT + M/N/E/I (Colemak-DH home row = left/down/up/right) are bound to focus moves.
# ALT is the Mac Option position because kanata swaps the physical Win and Alt keys.
# Needs a running Hyprland session. Run: tests/hypr-wm-focus.sh
#
# Real key presses cannot be tested here: wtype keycodes get remapped through the
# Colemak layout and /dev/uinput is root-only. Press the keys by hand to confirm.
set -u
fail=0
ALT=8

bound_to() { # key, expected description
  hyprctl binds -j | jq -e --arg k "$1" --arg d "$2" --argjson m "$ALT" \
    'any(.[]; (.key|ascii_downcase)==$k and .modmask==$m and .description==$d)' >/dev/null
}

check() { # key, description
  if bound_to "$1" "$2"; then echo "ok   - ALT+$1 -> $2"; else echo "FAIL - ALT+$1 -> $2"; fail=1; fi
}

check m "Focus on left window"
check n "Focus on below window"
check e "Focus on above window"
check i "Focus on right window"

# Arrow fallback (Omarchy default) must stay
for d in left right up down; do
  hyprctl binds -j | jq -e --arg k "$d" 'any(.[]; (.key|ascii_downcase)==$k and .modmask==64)' >/dev/null \
    && echo "ok   - SUPER+$d kept" || { echo "FAIL - SUPER+$d kept"; fail=1; }
done
exit $fail
