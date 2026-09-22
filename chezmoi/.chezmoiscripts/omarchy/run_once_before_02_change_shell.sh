#!/bin/sh
set -eu

# Set zsh as the default login shell (zsh is installed in 00_install_packages).
# Read the real login shell from passwd, not $SHELL, which only reflects the
# shell that invoked this script.
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH="$(command -v zsh)"
  LOGIN_SHELL="$(getent passwd "$(whoami)" | cut -d: -f7)"
  if [ "$LOGIN_SHELL" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
  fi
fi
