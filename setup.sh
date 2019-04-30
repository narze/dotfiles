#!/usr/bin/env bash

ANSIBLE_OPTS="$@"
ANSIBLE_TAGS=()
SETUP_BREW=
SETUP_CASK=
SETUP_MAS=
SETUP_ZSH=
SETUP_MPD=
SETUP_ASDF=
SETUP_TMUX=
SETUP_DOTFILES=
SETUP_NAS=

_q() {
  local QUESTION=$1
  local YESNO=""

  if [ -n "$ZSH_VERSION" ]; then
    read -s -k1 "YESNO?$QUESTION [Y/n]: "
  elif [ -n "$BASH_VERSION" ]; then
    read -s -n1 -r -p "$QUESTION [Y/n]: " YESNO
  else
    echo "Please use Zsh or Bash"
    exit 1
  fi

  if [[ "$YESNO" != "n" ]]; then
    YESNO="y"
  else
    YESNO="n"
  fi

  echo $YESNO
}

setup_ask() {
  local FULL_SETUP=$(_q "Full Setup ?") ; echo $FULL_SETUP

  if [[ $FULL_SETUP == "y" ]]; then
    ANSIBLE_TAGS+=('all')
  else
    SETUP_BREW=$(_q "Install Homebrew packages ?") ; echo $SETUP_BREW
    SETUP_CASK=$(_q "Install Homebrew Cask packages ?") ; echo $SETUP_CASK
    SETUP_MAS=$(_q "Install Mas packages?") ; echo $SETUP_MAS
    SETUP_ZSH=$(_q "Install Zsh with Zplug ?") ; echo $SETUP_ZSH
    SETUP_MPD=$(_q "Configure mpd ?") ; echo $SETUP_MPD
    SETUP_ASDF=$(_q "Install asdf with nodejs & yarn ?") ; echo $SETUP_ASDF
    SETUP_TMUX=$(_q "Configure tmux ?") ; echo $SETUP_TMUX
    SETUP_DOTFILES=$(_q "Softlink dotfiles ?") ; echo $SETUP_DOTFILES
    SETUP_NAS=$(_q "Setup your NAS ?") ; echo $SETUP_NAS

    if [[ $SETUP_BREW == "y" ]]; then ANSIBLE_TAGS+=('homebrew'); fi
    if [[ $SETUP_CASK == "y" ]]; then ANSIBLE_TAGS+=('cask'); fi
    if [[ $SETUP_MAS == "y" ]]; then ANSIBLE_TAGS+=('mas'); fi
    if [[ $SETUP_ZSH == "y" ]]; then ANSIBLE_TAGS+=('zsh'); fi
    if [[ $SETUP_MPD == "y" ]]; then ANSIBLE_TAGS+=('mpd'); fi
    if [[ $SETUP_ASDF == "y" ]]; then ANSIBLE_TAGS+=('asdf'); fi
    if [[ $SETUP_TMUX == "y" ]]; then ANSIBLE_TAGS+=('tmux'); fi
    if [[ $SETUP_DOTFILES == "y" ]]; then ANSIBLE_TAGS+=('dotfiles'); fi
    if [[ $SETUP_NAS == "y" ]]; then ANSIBLE_TAGS+=('nas'); fi
  fi
}

setup_xcode() {
  if ! command -v cc >/dev/null; then
    echo "Installing command line tools ..."
    xcode-select --install
  else
    echo "Command line tools already installed"
  fi
}

setup_homebrew() {
  if ! command -v brew >/dev/null; then
    echo "Installing Homebrew ..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    echo "Homebrew already installed"
  fi
}

setup_ansible() {
  if ! command -v ansible >/dev/null; then
    echo "Installing Ansible ..."
    brew install ansible
  else
    echo "Ansible already installed"
  fi
}

edit_secrets() {
  if [ ! -f ansible/secrets.yml ]; then
    cp ansible/secrets.yml.example ansible/secrets.yml
    vi ansible/secrets.yml
  fi
}

encrypt_secrets() {
  if head -1 ansible/secrets.yml | grep -v -q \$ANSIBLE_VAULT; then
    echo "Encrypting secrets.yml"
    ansible-vault encrypt ansible/secrets.yml
  fi
}

run_ansible_playbook() {
  tags=$(IFS=, ; echo "${ANSIBLE_TAGS[*]}")
  echo "Running Ansible playbook with tags : $tags"

  if ! ansible-playbook ansible/playbook.yml \
                        -i ansible/hosts \
                        --ask-vault-pass \
                        --tags $tags \
                        $ANSIBLE_OPTS; then
    echo "Error running Ansible playbook"
    exit 1
  fi
}

setup() {
  setup_ask
  setup_xcode
  setup_homebrew
  setup_ansible
  edit_secrets
  encrypt_secrets
  run_ansible_playbook
}

setup
echo "All done!"
