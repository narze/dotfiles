#!/bin/sh

apt install -y zsh

# Dependencies for asdf
apt install -y curl git

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.0
