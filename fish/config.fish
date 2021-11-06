# Paths
fish_add_path -ma $HOMEBREW_PREFIX/bin
fish_add_path -ma /opt/homebrew/bin
fish_add_path -ma $HOME/.dotfiles/etc/bin

if status is-interactive
  # Commands to run in interactive sessions can go here
  source ~/.config/fish/abbreviations
  zoxide init fish | source
end

# asdf
source ~/.asdf/asdf.fish
if ! test -e ~/.config/fish/completions/asdf.fish
  mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end

# go
set GOPATH $HOME/go
fish_add_path -ma $GOPATH/bin

# .local
fish_add_path -ma $HOME/.local/bin
