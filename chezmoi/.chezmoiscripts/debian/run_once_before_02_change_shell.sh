#!/bin/sh

# Set zsh as the default login shell (zsh is installed in 00_install_packages).
if command -v zsh >/dev/null 2>&1; then
  sudo chsh -s "$(command -v zsh)" "$(whoami)"
fi
