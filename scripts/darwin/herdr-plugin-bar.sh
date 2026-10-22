#!/bin/bash

# Install the jeffarese/herdr-bar plugin: a Cmd+K-style command bar to
# fuzzy-jump to any tab, agent, repo or branch. Bound to prefix+p in
# ~/.config/herdr/config.toml. Idempotent: installs only when missing.

if ! command -v herdr >/dev/null 2>&1; then
  echo "herdr not installed; skipping herdr-bar plugin"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not installed; skipping herdr-bar plugin"
  exit 0
fi

if herdr plugin list 2>/dev/null | grep -q '^- herdr-bar '; then
  exit 0
fi

echo "Installing herdr plugin jeffarese/herdr-bar"
herdr plugin install --yes jeffarese/herdr-bar
