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
)

# Omarchy ships mise-bin, which provides mise and conflicts with extra/mise.
# Only request mise when no mise binary is present yet.
if ! command -v mise >/dev/null 2>&1; then
  PKGS+=(mise)
fi

install_pkgs() {
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm --disable-download-timeout "$@"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm --disable-download-timeout "$@"
  else
    echo "Neither yay nor pacman found, skipping package install."
    return 0
  fi
}

# Mirrors can be flaky and abort a download with "Operation too slow".
# Retry the whole transaction before giving up.
for attempt in 1 2 3 4 5; do
  if install_pkgs "${PKGS[@]}"; then
    exit 0
  fi
  echo "Package install failed (attempt $attempt), retrying in 5s..." >&2
  sleep 5
done

echo "Package install failed after 5 attempts." >&2
exit 1
