# Paths
fish_add_path $HOMEBREW_PREFIX/bin
fish_add_path $HOME/.dotfiles/etc/bin

if status is-interactive
    # Commands to run in interactive sessions can go here
    source ~/.config/fish/abbreviations
end

zoxide init fish | source
