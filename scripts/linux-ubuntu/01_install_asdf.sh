#!/bin/sh

# Install/upgrade asdf

if [[ ! $(command -v asdf) ]]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
  source $HOME/.asdf/asdf.sh
else
  asdf update
fi
