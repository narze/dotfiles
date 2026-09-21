#!/bin/bash

# Kanata keyboard remapper (AUR). Runs once, only on Omarchy/Arch
# because .chezmoiignore excludes this folder on other systems.
set -u

if command -v kanata >/dev/null 2>&1; then
  echo "kanata already installed."
  exit 0
fi

if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm kanata-bin
elif command -v omarchy >/dev/null 2>&1; then
  omarchy pkg aur add kanata-bin
else
  echo "kanata-bin is AUR-only. Install yay or install kanata-bin manually."
  exit 0
fi
