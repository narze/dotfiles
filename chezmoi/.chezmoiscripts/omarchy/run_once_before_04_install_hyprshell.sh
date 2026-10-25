#!/bin/bash

# hyprshell window switcher (AUR). Runs once, only on Omarchy/Arch
# because .chezmoiignore excludes this folder on other systems.
set -u

if command -v hyprshell >/dev/null 2>&1; then
  echo "hyprshell already installed."
  exit 0
fi

if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm hyprshell
elif command -v omarchy >/dev/null 2>&1; then
  omarchy pkg aur add hyprshell
else
  echo "hyprshell is AUR-only. Install yay or install hyprshell manually."
  exit 0
fi
