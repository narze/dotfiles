#!/bin/sh

# Zoxide
curl -sS https://webinstall.dev/zoxide | bash

# ghq
asdf plugin add ghq
asdf install ghq latest
asdf global ghq latest
