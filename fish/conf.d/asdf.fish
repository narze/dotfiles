# asdf
source ~/.asdf/asdf.fish
if ! [ -e ~/.config/fish/completions/asdf.fish ]
  mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
