#!/bin/sh

# Debian "ai-agent" profile — additive layer on top of the minimal base.
# This runs after the minimal base (zsh, git, curl, unzip, mise) on every
# `chezmoi apply`, so keep every command idempotent.
#
# TODO: add ai-agent tools here (e.g. node/python runtimes, claude-code, ...).
