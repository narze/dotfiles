#!/usr/bin/env bash

ANSIBLE_OPTS="$@"

q() {
  QUESTION=$1

  local YESNO=""

  if [ -n "$ZSH_VERSION" ]; then
    read -s -k1 "YESNO?$QUESTION [Y/n]"
  elif [ -n "$BASH_VERSION" ]; then
    read -s -n1 -r -p "$QUESTION [Y/n]" YESNO
  else
    echo "Please use Zsh or Bash"
    exit 1
  fi

  if [[ "$YESNO" != "n" ]]; then
    YESNO=1
  else
    YESNO=""
  fi

  echo $YESNO
}

setup_ask() {
  local SETUP_FULL=$(q "Full Setup ?")

  echo

  if [[ -n $SETUP_FULL ]]; then
    echo "Full setup"
  else
    echo "Selective Setup"
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
  echo "Running Ansible playbook with playbook.yml ..."
  if ! ansible-playbook ansible/playbook.yml -i ansible/hosts --ask-vault-pass $ANSIBLE_OPTS; then
    echo "Error running Ansible playbook"
    exit 1
  fi
}

setup() {
  setup_xcode
  setup_homebrew
  setup_ansible
  edit_secrets
  encrypt_secrets
  run_ansible_playbook
}

setup
echo "All done!"
