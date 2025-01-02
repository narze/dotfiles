#!/bin/bash

# Path to the main SSH config file
SSH_CONFIG_FILE="$HOME/.ssh/config"

# Path to the managed SSH config file
INCLUDE_PATH=~/.ssh/managed_config

# The Include line that should be in the SSH config
INCLUDE_LINE="Include $INCLUDE_PATH"

# Check if the main SSH config file exists
if [ ! -f "$SSH_CONFIG_FILE" ]; then
  echo "$SSH_CONFIG_FILE does not exist"
  exit 0
fi

# Check if the Include line is already in the SSH config
if grep -Fxq "$INCLUDE_LINE" "$SSH_CONFIG_FILE"; then
  echo "Include line already exists in $SSH_CONFIG_FILE"
else
  echo "Adding Include line to $SSH_CONFIG_FILE"
  cat <<<"
# Managed by dotfiles
$INCLUDE_LINE

$(cat "$SSH_CONFIG_FILE")" >"$SSH_CONFIG_FILE.tmp"

  mv "$SSH_CONFIG_FILE.tmp" "$SSH_CONFIG_FILE"
fi
