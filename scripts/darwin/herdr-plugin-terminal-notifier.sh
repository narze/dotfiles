#!/bin/bash

# Install the dot/herdr-terminal-notifier plugin: clickable macOS notifications
# that focus the herdr pane whose agent changed state. Idempotent: installs only
# when missing.
#
# The first notification needs a one-time "Allow notifications" grant for
# "herdr" in System Settings -> Notifications; that cannot be scripted.

if ! command -v herdr >/dev/null 2>&1; then
  echo "herdr not installed; skipping terminal-notifier plugin"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping terminal-notifier plugin"
  exit 0
fi

if herdr plugin list 2>/dev/null | grep -q 'dot.terminal-notifier'; then
  exit 0
fi

echo "Installing herdr plugin dot/herdr-terminal-notifier"
herdr plugin install --yes dot/herdr-terminal-notifier
