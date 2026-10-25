#!/bin/bash

# Start the hyprshell user service. Runs once, after files are applied so that
# ~/.config/hyprshell/config.toml exists.
set -u

if ! command -v hyprshell >/dev/null 2>&1; then
  echo "hyprshell is not installed, skipping service setup."
  exit 0
fi

systemctl --user enable --now hyprshell.service
