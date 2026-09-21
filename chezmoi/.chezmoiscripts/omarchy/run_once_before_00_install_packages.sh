#!/bin/bash

# Omarchy (Arch-based) base packages. Runs once, only on Omarchy/Arch
# because .chezmoiignore excludes this folder on other systems.
set -u

PKGS=(
  zsh
  git
  curl
  wget
  unzip
  bc
  zoxide
  git-delta
  github-cli
  ghq
  zellij
  tmux
  fzf
  ripgrep
  fd
  bat
  eza
  jq
  starship
  mise
)

if command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm "${PKGS[@]}"
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm "${PKGS[@]}"
else
  echo "Neither yay nor pacman found, skipping package install."
fi
