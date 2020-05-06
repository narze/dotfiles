# Dotfiles [![Build Status](https://travis-ci.com/narze/dotfiles.svg?branch=master)](https://travis-ci.com/narze/dotfiles)
(Formerly named `laptop`) Bootstrap my macOS machines, for fun & profit.

## From Ansible to Dotbot
I decided to migrate all Ansible playbooks to [Dotbot](https://github.com/anishathalye/dotbot) and plain shell scripts. Switch to [ansible branch](https://github.com/narze/dotfiles/tree/ansible) if you still want to use Ansible.

Ansible has served me well for years, but the Playbooks grew over time into multiple long-running scripts. Moreover, I think I messed up the configuration and the dependencies between the playbooks as well. Now to add just a new symlink I have to edit multiple files and my `setup.sh` file is badly designed too.

Some Ansible playbooks will still be here until I moved all scripts to `Makefile` and Dotbot config files.

## Usage
```shell
git clone git@github.com:narze/dotfiles.git ~/dotfiles
cd ~/dotfiles && make bootstrap
```

## Features
```
$ make
help                           Print command list
bootstrap                      Bootstrap new machine
dotfiles                       Update dotfiles
macos                          Run macos script
code                           Clone Repositories with ghq
brew                           Install brew & cask packages
tools                          Install non-brew tools eg. tmux package manager
asdf                           Install asdf-vm
sync                           Sync local configuration from Google Drive, Dropbox, etc.
update                         Update everything
all                            Run all tasks at once
```

### Installed Applications & Tools
- [Homebrew](https://brew.sh)
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask)
- [Mas](https://github.com/mas-cli/mas)
- [zsh](http://zsh.org/) with [zinit](https://github.com/zdharma/zinit) (Formerly zplugin)
- [asdf](https://asdf-vm.com) with Ruby & Node.js
- [tmux](https://github.com/tmux/tmux/)
- [macOS defaults](./etc/macos)
- Actual [dotfiles](./etc)
- ~/Code for workspace with [public repos](./code.conf.yml)
- etc.

### Known Issues
Some packages needs reloading shell (eg. `asdf`) On a fresh macOS you may have to run setup command once, and run again in a new tab which has $PATH reloaded.

### TODOs
- [ ] Modify system preferences
  - Keyboard shortcuts
  - Keyboard layouts
- [x] Migrate Ansible Playbooks to Dotbot config
- [ ] Add folders to Favorites in Finder
- [x] Redesign setup script
  - Separate bootstrap script (first run on vanilla) from update script
  - Print readme when bootstrap script is done, eg. login & sync Dropbox & Google Drive & 1Password & Restore mackup
  - Remember & retry on failed step
