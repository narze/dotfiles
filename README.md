# Dotfiles

I don't want to waste time setting up my machines, so I spent years maintaining dotfiles.

[Dotfiles are meant to be forked,](https://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked) but mine aren't. These scripts install many things you won't ever use. Feel free to look around and copy some of my script to fit your needs.

## Chezmoi

The latest version of my dotfiles are managed with [Chezmoi](https://chezmoi.io). I was using [Dotbot](https://github.com/narze/dotfiles/tree/dotbot) & [Ansible](https://github.com/narze/dotfiles/tree/ansible) before.

### TODOs

- [x] Fix Fish shell broken in clean install
- [x] Add Homebrew install script (run-once)
- [x] Update this readme
- [x] Cleanup dotbot
- [x] Linux / Github Codespaces install scripts
- [x] Github Codespaces for development
- [ ] `Fish`
- [ ] Documentation website
- [ ] Instructions to import GPG keys
- [x] 1password integration

## Usage

```shell
ASK=1 sh -c "$(curl -fsSL https://raw.githubusercontent.com/narze/dotfiles/master/remote_install.sh) -k -v"
```

First installation will ask for your name so you can customize a bit, and it will skip the encryped files, since you have to retrieve the GPG private key manually later. Removing `ASK=1` will use my names for the machine.

Mostly the script will not run completely on the first go, run `chezmoi -k apply` again until everything is setup properly.

After the first installation you can always change the variables via `ASK=1 chezmoi init` or run `chezmoi edit-config`

To change the data or script, `chezmoi cd`, edit them, then run `chezmoi apply`.

## Manual tasks (One-time per machine)

- macOS
  - Syncthing
    - Run Syncthing and sync default folder to `~/Sync`
  - Karabiner Elements
    - Rename default profile to `Default`
    - Allow permissions, reboot
  - Keyboard Maestro
    - Open sync file `~/Sync/Apps/Keyboard Maestro/Keyboard Maestro Macros.kmsync`
  - Raycast
    - Setup shortcut key to `Ctrl+Space`
    - Import data from iCloud drive
  - Vivaldi Browser
    - Login & sync data
    - Manually mirror settings & keyboard shortcuts
    - Manually add workspace rules
  - Install apps in Setapp
  - Cleanshot
    - Set keyboard shortcuts & disable system shortcuts
  - Session
    - Enable "break_start" shortcut trigger
  - Time Out
    - Add "Normal" & "Micro" break but disabled them
  - Login to Mac App Store
  - System Settings
    - Keyboard Shortcuts
      - Change input source switch to CMD+Space, and Spotlight search to Option+Space
  - Connect to Tailscale to mount NAS
  - Disable Boom 3D keyboard shortcuts
  - Set enrcyption password `SETPASS=1 chezmoi init`

## Features

```shell
$ make
help                           Print command list
dotfiles                       Update dotfiles
apply                          Run chezmoi apply
macos                          Run macos script
```

### Installed Applications & Tools

- macOS
  - [Homebrew](https://brew.sh)
  - [Homebrew Cask](https://github.com/Homebrew/homebrew-cask)
  - [Mas](https://github.com/mas-cli/mas)
  - [Chezmoi](https://chezmoi.io)
  - [zsh](https://zsh.org) with [zsh4humans](https://github.com/romkatv/zsh4humans) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
  - [fish](https://fishshell.com) with [fisher](https://github.com/jorgebucaran/fisher) + [Tide](https://github.com/IlanCosman/tide) theme
  - [mise](https://mise.jdx.dev)
  - [zellij](https://zellij.dev)
  - [macOS defaults](https://mths.be/macos)
  - etc.
- Linux
  - Dotfiles only

<details>
  <summary><b>Notes</b> (If you have some time to read)</summary>

### Zsh + Fish

After the recent [drama with Zinit](https://github.com/zdharma-continuum/I_WANT_TO_HELP), I decided to give [Fish](https://fishshell.com) a try, it is good but I also want to still maintain my Zsh configuration. I migrated the settings to [zsh4human](https://github.com/romkatv/zsh4humans) which is maintained by the one who made Powerlevel10k. It's 2-3x faster than Zinit as of now.

I'll separate the dotfiles script to install zsh or fish separately to save some space. You can also install both like mine.

### Development on Github Codespaces

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=master&repo=101657113&machine=standardLinux32gb)

- `chezmoi cd` (Change directory into `~/.local/share/chezmoi`)
- Update config and/or scripts
- `chezmoi apply -k` (--keep-going)

### Apple Silicon

Here are the list of issues I've found on running the script on M1 Macbooks (Tested on both Macbook Air & Macbook Pro)

- ~~dotbot/brew fails silently : Now they need XCode to be installed first (via App Store), rather than just XCode CLT~~ Seems to be fixed now
- ~~Kitty.app installing binaries from Homebrew does get you x86, now you have to [Build from source](https://sw.kovidgoyal.net/kitty/build.html)~~

  - ```shell
    ghq get -l kovidgoyal/kitty
    /opt/homebrew/bin/python3 setup.py kitty.app # Needs python3 from brew
    cp -r kitty.app /Applications/kitty.app

    # Replace CLI
    rm /opt/homebrew/bin/kitty
    ln -s $PWD/kitty/launcher/kitty /opt/homebrew/bin/kitty
    ```

  - If you want both versions, download the executable and rename it (`kitty_x86.app`)

- ~~Docker for Mac : Replace with [Tech Preview version](https://docs.docker.com/docker-for-mac/apple-m1)~~
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
- Yabai : Cannot use space switch commands (eg. `yabai -m space --focus 1`) even if SIP is disabled
  <details>
    <summary>Workaround</summary>

  Setup native shortcut keys manually and use non-consuming shortcut settings (`->`) in `skhd`
  ![image](https://user-images.githubusercontent.com/248741/111079897-a77e6380-852e-11eb-92d5-42f743dc3060.png)
  </details>

### ~~Apple Silicon specific commands~~

- `make brew-x86` : Install packages which cannot be instaled with `arm64` arch right now (eg. ~~`kubectl`, `kubectx`~~ Both are now supported!)
- </details>
