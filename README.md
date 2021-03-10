# Dotfiles [![Build Status](https://travis-ci.com/narze/dotfiles.svg?branch=master)](https://travis-ci.com/narze/dotfiles)

(Formerly named `laptop`) Bootstrap my macOS machines, for fun & profit.

## Usage

```shell
git clone https://github.com/narze/dotfiles ~/dotfiles
cd ~/dotfiles && make bootstrap

# Optional : Change to SSH url for pushing updates
git remote set-url origin git@github.com:narze/dotfiles.git
```

## Apple Silicon

Here are the list of issues I've found on running the script on M1 Macbooks (Tested on both Macbook Air & Macbook Pro)

- ~~dotbot/brew fails silently : Now they need XCode to be installed first (via App Store), rather than just XCode CLT~~ Seems to be fixed now
- Kitty.app installing binaries from Homebrew does get you x86, now you have to [Build from source](https://sw.kovidgoyal.net/kitty/build.html)
  - ```shell
    ghq get -l kovidgoyal/kitty
    /opt/homebrew/bin/python3 setup.py kitty.app # Needs python3 from brew
    cp -r kitty.app /Applications/kitty.app

    # Replace CLI
    rm /opt/homebrew/bin/kitty
    ln -s $PWD/kitty/launcher/kitty /opt/homebrew/bin/kitty
    ```
  - If you want both versions, download the executable and rename it (`kitty_x86.app`)
- Docker for Mac : Replace with [Tech Preview version](https://docs.docker.com/docker-for-mac/apple-m1)
- ~~Some brew/asdf packages cannot be installed on arm64~~ See "Apple Silicon specific commands"
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

### Apple Silicon specific commands

- `make brew-x86` : Install packages which cannot be instaled with `arm64` arch right now (eg. `kubectl`, `kubectx`)

## Manual tasks (One-time per machine)

- Preferences -> Change input source switch to CMD+Space, and Spotlight search to Option+Space
- `asdf` needs shell reloading once after installation. Run setup command `make asdf` once, open a new terminal, then run `make asdf` again.
- `mackup restore` : Run once after Syncthing is installed and `~/Sync/Mackup` is synced.

## Features

```
$ make
help                           Print command list
bootstrap                      Bootstrap new machine
dotfiles                       Update dotfiles
macos                          Run macos script
code                           Clone Repositories with ghq
brew                           Install brew & cask packages
brew-light                     Install light version of brewfile (Minimal)
brew-x86                       Install x86-compatible Homebrew packages (Expected to Apple Silicon Macs)
tools                          Install non-brew tools eg. tmux package manager
asdf                           Install asdf-vm
sync                           Sync local configuration from Google Drive, Dropbox, etc.
update                         Update everything
vim                            Setup vim
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
