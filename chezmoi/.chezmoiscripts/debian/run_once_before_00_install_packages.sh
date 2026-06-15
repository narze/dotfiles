#!/bin/sh

# Debian minimal base — runs for every profile.
# OS/profile gating is handled in .chezmoiignore.

sudo apt update

sudo apt install -y unzip zsh

# Dependencies for mise
sudo apt install -y curl git
