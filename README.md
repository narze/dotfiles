Bootstrap my macOS machines, for fun & profit.

## Usage
```shell
git clone git@github.com:Raven283/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && make bootstrap
```

## Features
```
❯ make
help                           Print command list
bootstrap                      Bootstrap new machine
dotfiles                       Update dotfiles
code                           Clone Repositories with ghq
brew                           Install brew & cask packages
tools                          Install non-brew tools eg. tmux package manager
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
- [ ] Migrate Ansible Playbooks to Dotbot config
- [ ] Add folders to Favorites in Finder
- [ ] Redesign setup script
  - Separate bootstrap script (first run on vanilla) from update script
  - Print readme when bootstrap script is done, eg. login & sync Dropbox & Google Drive & 1Password & Restore mackup
  - Remember & retry on failed step
