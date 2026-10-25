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

# Digit binds use physical keycodes (code:N), which hyprctl reports with an empty key,
# so they are matched by modmask and description only.
by_desc() { # modmask, description
  hyprctl binds -j | jq -e --arg d "$2" --argjson m "$1" 'any(.[]; .modmask==$m and .description==$d)' >/dev/null
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
  if by_desc $ALT_SHIFT "Move window to workspace $n"; then echo "ok   - ALT+SHIFT+$n -> Move window to workspace $n"; else echo "FAIL - ALT+SHIFT+$n -> Move window to workspace $n"; fail=1; fi
done

# Switch workspace on ALT+1..8 instead of SUPER+1..8 (yabai: alt+1..8)
for n in 1 2 3 4 5 6 7 8; do
  if by_desc $ALT "Switch to workspace $n"; then echo "ok   - ALT+$n -> Switch to workspace $n"; else echo "FAIL - ALT+$n -> Switch to workspace $n"; fail=1; fi
  if by_desc 64 "Switch to workspace $n"; then echo "FAIL - SUPER+$n still bound"; fail=1; else echo "ok   - SUPER+$n unbound"; fi
done

# Previous/next workspace (yabai: alt+l, alt+0x23, the physical P key, ; on Colemak-DH)
check l "Previous workspace"
# Plain physical P reaches Hyprland as ALT+SHIFT+code:33 because kanata's ; <-> : override adds Shift
if by_desc $ALT_SHIFT "Next workspace"; then echo "ok   - ALT+(physical P) -> Next workspace"; else echo "FAIL - ALT+(physical P) -> Next workspace"; fail=1; fi

# Move window to previous/next workspace and stay (yabai: alt+shift+l, alt+shift+0x23).
# Real Shift+P is turned into plain P by kanata, so "next" arrives as ALT+code:33 without Shift.
check l "Move window to previous workspace" $ALT_SHIFT ALT+SHIFT
if by_desc $ALT "Move window to next workspace"; then echo "ok   - ALT+SHIFT+(physical P) -> Move window to next workspace"; else echo "FAIL - ALT+SHIFT+(physical P) -> Move window to next workspace"; fail=1; fi

# Move window to the monitor on the left/right and follow it (yabai: alt+shift+u/y)
check u "Move window to left monitor" $ALT_SHIFT ALT+SHIFT
check y "Move window to right monitor" $ALT_SHIFT ALT+SHIFT

# Focus monitor (yabai: alt+u west, alt+y east)
check u "Focus on left monitor"
check y "Focus on right monitor"

# SUPER+W sends CTRL+W to every app (Cmd+W on macOS), ALT+W closes the window (yabai: alt+w)
check w "Universal close (CTRL+W)" 64 SUPER
check w "Close window"

# CTRL+SPACE opens the launcher, SUPER+SPACE toggles the keyboard layout (CTRL=4)
check space "Omarchy menu" 4 CTRL
check space "Toggle keyboard layout" 64 SUPER

# Window state keys moved from SUPER to ALT (yabai/OmniWM). Format: new modmask, old modmask, description.
# modmask: SHIFT=1 CTRL=4 ALT=8 SUPER=64
moved() {
  local new=$1 old=$2 desc=$3
  if by_desc "$new" "$desc"; then echo "ok   - ALT bind: $desc"; else echo "FAIL - ALT bind: $desc"; fail=1; fi
  if by_desc "$old" "$desc"; then echo "FAIL - old SUPER bind still there: $desc"; fail=1; else echo "ok   - old SUPER bind removed: $desc"; fi
}
moved 8 64 "Full screen"                       # alt+f
moved 8 68 "Tiled full screen"                 # alt+z (was SUPER+CTRL+F, so the old mask is 68)
moved 8 64 "Toggle window floating/tiling"     # alt+t
moved 8 64 "Toggle window split"               # alt+c
moved 8 64 "Toggle workspace layout"           # alt+r
moved 8 64 "Toggle scratchpad"                 # alt+s
moved 9 72 "Move window to scratchpad"         # alt+shift+s
moved 8 64 "Expand window left"                # alt+-
moved 8 64 "Shrink window left"                # alt+=
moved 9 65 "Shrink window up"                  # alt+shift+-
moved 9 65 "Expand window down"                # alt+shift+=

# Omarchy defaults for 9 and 0 stay
for n in 9 10; do
  if by_desc 64 "Switch to workspace $n"; then echo "ok   - SUPER+$n kept"; else echo "FAIL - SUPER+$n kept"; fail=1; fi
done

# Arrow fallback (Omarchy default) must stay
for d in left right up down; do
  hyprctl binds -j | jq -e --arg k "$d" 'any(.[]; (.key|ascii_downcase)==$k and .modmask==64)' >/dev/null \
    && echo "ok   - SUPER+$d kept" || { echo "FAIL - SUPER+$d kept"; fail=1; }
done
exit $fail
