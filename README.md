# Laptop
macOS setup script for development

## Usage
```shell
git clone https://github.com/narze/laptop.git ~/laptop
cd ~/laptop && sh ./setup.sh
```

## Features
Setup packages, dotfiles, and bootstrap environment via Ansible playbook, you can skip some of the steps or run all steps.

### Installed Applications & Tools
- [Homebrew](https://brew.sh), with [apps](./ansible/roles/packages/tasks/homebrew.yml)
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask), with [apps](./ansible/roles/packages/tasks/cask.yml)
- [Mas](https://github.com/mas-cli/mas), with [apps](./ansible/roles/packages/tasks/mas.yml)
- [zsh](http://zsh.org/) with [zplug](https://github.com/zplug/zplug)
- [asdf](https://asdf-vm.com) with Ruby & Node.js
- [tmux](https://github.com/tmux/tmux/)
- [Docker for macOS](https://docs.docker.com/docker-for-mac/), with [prebuilt images](./ansible/roles/packages/tasks/docker.yml)
- [macOS defaults](./etc/macos)
- My [dotfiles](./etc)
- etc.

## TODO
- macOS preferences script (eg. non-natural scrollbar, Colemak & Pattachote layouts)
