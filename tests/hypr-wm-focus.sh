#!/usr/bin/env bash
# Checks the yabai-style ALT bindings: M/N/E/I (Colemak-DH home row = left/down/up/right)
# for focus, ALT+SHIFT for swap, ALT+SHIFT+1..8 for move to workspace.
# ALT is the Mac Option position because kanata swaps the physical Win and Alt keys.
# Needs a running Hyprland session. Run: tests/hypr-wm-focus.sh
#
# Real key presses cannot be tested here: wtype keycodes get remapped through the
# Colemak layout and /dev/uinput is root-only. Press the keys by hand to confirm.
set -u
fail=0
ALT=8
ALT_SHIFT=9

bound_to() { # key, expected description, modmask
  hyprctl binds -j | jq -e --arg k "$1" --arg d "$2" --argjson m "${3:-$ALT}" \
    'any(.[]; (.key|ascii_downcase)==$k and .modmask==$m and .description==$d)' >/dev/null
}

check() { # key, description, [modmask, label]
  local label=${4:-ALT}
  if bound_to "$1" "$2" "${3:-$ALT}"; then echo "ok   - $label+$1 -> $2"; else echo "FAIL - $label+$1 -> $2"; fail=1; fi
}

check m "Focus on left window"
check n "Focus on below window"
check e "Focus on above window"
check i "Focus on right window"

# Swap windows in place (yabai: alt+shift+m/n/e/i)
check m "Swap window to the left" $ALT_SHIFT ALT+SHIFT
check n "Swap window down" $ALT_SHIFT ALT+SHIFT
check e "Swap window up" $ALT_SHIFT ALT+SHIFT
check i "Swap window to the right" $ALT_SHIFT ALT+SHIFT

# Send window to workspace, stay on current one (yabai: shift+alt+1..8)
for n in 1 2 3 4 5 6 7 8; do
  check "$n" "Move window to workspace $n" $ALT_SHIFT ALT+SHIFT
done

# Arrow fallback (Omarchy default) must stay
for d in left right up down; do
  hyprctl binds -j | jq -e --arg k "$d" 'any(.[]; (.key|ascii_downcase)==$k and .modmask==64)' >/dev/null \
    && echo "ok   - SUPER+$d kept" || { echo "FAIL - SUPER+$d kept"; fail=1; }
done
exit $fail
