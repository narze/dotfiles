if [[ ! -f ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/@zpm/zpm.zsh ]]; then
  git clone --recursive https://github.com/zpm-zsh/zpm "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/@zpm"
fi
source "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/@zpm/zpm.zsh"

# Plugins
# Note: Some are not working
zpm load olets/zsh-abbr
zpm load mollifier/cd-gitroot
zpm load romkatv/zsh-defer
# zpm load zsh-users/zsh-syntax-highlighting
zpm load zsh-users/zsh-history-substring-search
zpm load zsh-users/zsh-autosuggestions
