#!/bin/sh

# Set zsh as the default login shell (zsh is installed in 00_install_packages).
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH="$(command -v zsh)"
  if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
  fi
fi
