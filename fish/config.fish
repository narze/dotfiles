# Paths
## go
set GOPATH $HOME/go
fish_add_path $GOPATH/bin

## .local
fish_add_path $HOME/.local/bin

# Homebrew
if [ (arch) = arm64 ]
  if [ -e /usr/local/bin/brew ]
    eval (/usr/local/bin/brew shellenv)
  end

  if [ -e /opt/homebrew/bin/brew ]
    eval (/opt/homebrew/bin/brew shellenv)
  end
else
  if [ -e /opt/homebrew/bin/brew ]
    eval (/opt/homebrew/bin/brew shellenv)
  end

  if [ -e /usr/local/bin/brew ]
    eval (/usr/local/bin/brew shellenv)
  end
end

if [ -e ~/homebrew/bin/brew ]
  eval (~/homebrew/bin/brew shellenv)
end

if status is-interactive
  # Commands to run in interactive sessions can go here
  source ~/.config/fish/abbreviations
  zoxide init fish | source
end

# asdf
source ~/.asdf/asdf.fish
if ! [ -e ~/.config/fish/completions/asdf.fish ]
  mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end

# Tide
## Arch
function _tide_item_arch
  set -l arch (uname -m)

  if [ $arch = arm64 ]
    _tide_print_item arch 'arm'
  else if [ $arch = x86_64 ]
    _tide_print_item arch 'x86'
  end
end
set -U tide_arch_color white
set -U tide_arch_bg_color black

## Fish
function _tide_item_fish
  _tide_print_item fish ''
end
set -U tide_fish_color black
set -U tide_fish_bg_color red

## Prompt
set -U tide_left_prompt_items fish arch pwd git newline character
