# Dotfiles [![Build Status](https://travis-ci.com/narze/dotfiles.svg?branch=master)](https://travis-ci.com/narze/dotfiles)

(Formerly named `laptop`) Bootstrap my macOS machines, for fun & profit.

## Issues with Apple Silicon (M1)

Here are the list of issues I've found on running the script on M1 Macbooks

- dotbot/brew fails silently : Now they need XCode to be installed first (via App Store), rather than just XCode CLT
- Kitty.app installing binaries from Homebrew does get you x86, now you have to [Build from source](https://sw.kovidgoyal.net/kitty/build.html)
  - If you want both versions, download the executable and rename it (`kitty_x86.app`)
- Docker for Mac : Replace with [Tech Preview version](https://docs.docker.com/docker-for-mac/apple-m1)
- Some brew/asdf packages cannot be installed on arm64
  - `asdf-direnv`
  - `neovim`
- Setup both versions of Homebrew, then use shell script to point to the correct `brew`

  ```shell
  # Install both versions
  arch -arm64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # .zshrc
  if [ "$(uname -m)" == "arm64" ]; then
    # Use arm64 brew, with fallback to x86 brew
    if [ -f /opt/homebrew/bin/brew ]; then
      export PATH="/usr/local/bin${PATH+:$PATH}";
      eval $(/opt/homebrew/bin/brew shellenv)
    fi
  else
    # Use x86 brew, with fallback to arm64 brew
    if [ -f /usr/local/bin/brew ]; then
      export PATH="/opt/homebrew/bin${PATH+:$PATH}";
      eval $(/usr/local/bin/brew shellenv)
    fi
  fi
  ```

- Rubygems : Specific bundler config is needed (See `bundle config`)

## Apple Silicon specific commands

- `make brew-x86` : Install packages which cannot be instaled with `arm64` arch right now (eg. `kubectl`, `kubectx`)

## Manual tasks

Some cannot be automated right now

- Preferences -> Change input source switch to CMD+Space, and Spotlight search to Option+Space

## From Ansible to Dotbot

I decided to migrate all Ansible playbooks to [Dotbot](https://github.com/anishathalye/dotbot) and plain shell scripts. Switch to [ansible branch](https://github.com/narze/dotfiles/tree/ansible) if you still want to use Ansible.

Ansible has served me well for years, but the Playbooks grew over time into multiple long-running scripts. Moreover, I think I messed up the configuration and the dependencies between the playbooks as well. Now to add just a new symlink I have to edit multiple files and my `setup.sh` file is badly designed too.

Some Ansible playbooks will still be here until I moved all scripts to `Makefile` and Dotbot config files.

## Usage

```shell
git clone https://github.com/narze/dotfiles ~/dotfiles
cd ~/dotfiles && make bootstrap

# Optional : Change to SSH url for pushing updates
git remote set-url origin git@github.com:narze/dotfiles.git
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
- ~/Code for workspace with [public repos](./config/code.conf.yml)
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
