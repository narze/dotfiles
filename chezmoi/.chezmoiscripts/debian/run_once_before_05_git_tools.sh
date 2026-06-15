#!/bin/bash

# Install git-delta and gh CLI on Debian.
# delta enables the pager configured in ~/.gitconfig.
# gh enables the credential helper configured in ~/.gitconfig.

set -euo pipefail

# git-delta
if ! command -v delta >/dev/null 2>&1; then
  echo "Installing git-delta..."
  DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  DELTA_VERSION=${DELTA_VERSION#v}
  if [ -n "$DELTA_VERSION" ]; then
    TMP=$(mktemp -d)
    wget -qO "$TMP/delta.deb" \
      "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
    sudo dpkg -i "$TMP/delta.deb"
    rm -rf "$TMP"
  else
    echo "Could not determine delta version, skipping."
  fi
fi

# gh CLI
if ! command -v gh >/dev/null 2>&1; then
  echo "Installing gh CLI..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
fi
