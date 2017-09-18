#!/usr/bin/env bash

ANSIBLE_OPTS="$@"

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

run_ansible_playbook() {
  echo "Running Ansible playbook with playbook.yml ..."
  if ! ansible-playbook ansible/playbook.yml -i ansible/hosts -K $ANSIBLE_OPTS; then
    echo "Error running Ansible playbook"
    exit 1
  fi
}

setup() {
  setup_xcode
  setup_homebrew
  setup_ansible
  edit_secrets
  run_ansible_playbook
}

setup
echo "All done!"
