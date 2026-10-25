#!/usr/bin/env bash
# Checks that hyprshell (macOS Cmd+Tab style window switcher) is set up on SUPER+TAB.
# Needs a running Hyprland session. Run: tests/hyprshell.sh
set -u
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
t() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }

t "hyprshell installed" command -v hyprshell
t "config is valid" hyprshell config check
t "switch mode uses the super modifier" bash -c 'hyprshell config explain 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -q "Press Super + tab"'
t "daemon is enabled" systemctl --user is-enabled hyprshell
t "daemon is running" systemctl --user is-active hyprshell

# Omarchy's SUPER+TAB (next workspace) must not compete with the switcher
omarchy_tab() { hyprctl binds -j | jq -e --arg d "$1" 'any(.[]; .modmask==64 and .description==$d)' >/dev/null; }
omarchy_tab "Next workspace" && bad "Omarchy SUPER+TAB unbound" || ok "Omarchy SUPER+TAB unbound"
exit $fail
