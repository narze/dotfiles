#!/bin/sh

# Debian "homelab" profile — additive layer on top of the minimal base.
# This runs after the minimal base (zsh, git, curl, unzip, mise) on every
# `chezmoi apply`, so keep every command idempotent.
#
# TODO: add homelab tools here (e.g. docker, tailscale, restic, ...).
