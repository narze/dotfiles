#!/usr/bin/env bash

ANSIBLE_OPTS="$@"
ANSIBLE_TAGS=()
SETUP_BREW=
SETUP_CASK=
SETUP_CASK_UPGRADE=
SETUP_MAS=
SETUP_ZSH=
SETUP_MPD=
SETUP_TMUX=
SETUP_DOTFILES=
SETUP_NAS=
SETUP_LOCAL=
SETUP_MACOS=
SETUP_CODE=
SETUP_ASDF=
SETUP_RUBY=
SETUP_DOCKER=
STEPS=16

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
    STEP=1
    SETUP_BREW=$(_q "[$STEP/$STEPS] Install Homebrew packages ?") ; echo $SETUP_BREW ; STEP=$((STEP+1))
    SETUP_CASK=$(_q "[$STEP/$STEPS] Install Homebrew Cask packages ?") ; echo $SETUP_CASK ; STEP=$((STEP+1))
    SETUP_CASK_UPGRADE=$(_q "[$STEP/$STEPS] Upgrade Homebrew Cask packages ?") ; echo $SETUP_CASK_UPGRADE ; STEP=$((STEP+1))
    SETUP_MAS=$(_q "[$STEP/$STEPS] Install Mas packages?") ; echo $SETUP_MAS ; STEP=$((STEP+1))
    SETUP_ZSH=$(_q "[$STEP/$STEPS] Install Zsh with zinit ?") ; echo $SETUP_ZSH ; STEP=$((STEP+1))
    SETUP_MPD=$(_q "[$STEP/$STEPS] Configure mpd ?") ; echo $SETUP_MPD ; STEP=$((STEP+1))
    SETUP_TMUX=$(_q "[$STEP/$STEPS] Configure tmux ?") ; echo $SETUP_TMUX ; STEP=$((STEP+1))
    SETUP_DOTFILES=$(_q "[$STEP/$STEPS] Softlink dotfiles ?") ; echo $SETUP_DOTFILES ; STEP=$((STEP+1))
    SETUP_NAS=$(_q "[$STEP/$STEPS] Setup your NAS ?") ; echo $SETUP_NAS ; STEP=$((STEP+1))
    SETUP_LOCAL=$(_q "[$STEP/$STEPS] Sync local config on Google Drive ?") ; echo $SETUP_LOCAL ; STEP=$((STEP+1))
    SETUP_MACOS=$(_q "[$STEP/$STEPS] Setup Sensible macOS defaults ?") ; echo $SETUP_MACOS ; STEP=$((STEP+1))
    SETUP_CODE=$(_q "[$STEP/$STEPS] Setup Code folder ?") ; echo $SETUP_CODE ; STEP=$((STEP+1))
    SETUP_ASDF=$(_q "[$STEP/$STEPS] Install asdf with nodejs & yarn ?") ; echo $SETUP_ASDF ; STEP=$((STEP+1))
    SETUP_RUBY=$(_q "[$STEP/$STEPS] Setup Ruby ?") ; echo $SETUP_RUBY ; STEP=$((STEP+1))
    SETUP_DOCKER=$(_q "[$STEP/$STEPS] Pull Docker images ?") ; echo $SETUP_DOCKER ; STEP=$((STEP+1))

    if [[ $SETUP_BREW == "y" ]]; then ANSIBLE_TAGS+=('homebrew'); fi
    if [[ $SETUP_CASK == "y" ]]; then ANSIBLE_TAGS+=('cask'); fi
    if [[ $SETUP_CASK_UPGRADE == "y" ]]; then ANSIBLE_TAGS+=('cask_upgrade'); fi
    if [[ $SETUP_MAS == "y" ]]; then ANSIBLE_TAGS+=('mas'); fi
    if [[ $SETUP_ZSH == "y" ]]; then ANSIBLE_TAGS+=('zsh'); fi
    if [[ $SETUP_MPD == "y" ]]; then ANSIBLE_TAGS+=('mpd'); fi
    if [[ $SETUP_TMUX == "y" ]]; then ANSIBLE_TAGS+=('tmux'); fi
    if [[ $SETUP_DOTFILES == "y" ]]; then ANSIBLE_TAGS+=('dotfiles'); fi
    if [[ $SETUP_NAS == "y" ]]; then ANSIBLE_TAGS+=('nas'); fi
    if [[ $SETUP_LOCAL == "y" ]]; then ANSIBLE_TAGS+=('local_sync'); fi
    if [[ $SETUP_MACOS == "y" ]]; then ANSIBLE_TAGS+=('macos'); fi
    if [[ $SETUP_CODE == "y" ]]; then ANSIBLE_TAGS+=('code'); fi
    if [[ $SETUP_ASDF == "y" ]]; then ANSIBLE_TAGS+=('asdf'); fi
    if [[ $SETUP_RUBY == "y" ]]; then ANSIBLE_TAGS+=('ruby'); fi
    if [[ $SETUP_DOCKER == "y" ]]; then ANSIBLE_TAGS+=('docker'); fi
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
