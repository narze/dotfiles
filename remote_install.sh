#!/bin/sh

# Install remotely from single shell command
# Usage : sh -c "$(curl -fsSL https://raw.githubusercontent.com/narze/dotfiles/chezmoi/remote_install.sh)"

echo "Installing Xcode Command Line Tools"
xcode-select --install

set -e # -e: exit on error

if [ ! "$(command -v chezmoi)" ]; then
  bin_dir="$HOME/.local/bin"
  chezmoi="$bin_dir/chezmoi"
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
else
  chezmoi=chezmoi
fi

# exec: replace current process with chezmoi init
exec "$chezmoi" init --apply narze
