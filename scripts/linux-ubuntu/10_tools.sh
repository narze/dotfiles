#!/bin/sh

# Zoxide
curl -sS https://webinstall.dev/zoxide | bash

# ghq
asdf plugin add ghq
asdf install ghq latest
asdf global ghq latest

# direnv
asdf plugin add direnv
asdf install direnv latest
asdf global direnv latest

# neovim
asdf plugin add neovim
asdf install neovim latest
asdf global neovim latest
