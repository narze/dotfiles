#!/bin/bash

# "ai-agent" Debian profile — runs on top of the minimal base.

echo "Setting up Debian 'ai-agent' profile..."

# Claude Code CLI
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# opencode CLI
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/install | bash
fi
