### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

# Byte-compile zinit core when missing or stale (zinit only does this on self-update)
() {
  local f
  for f in $HOME/.local/share/zinit/zinit.git/zinit*.zsh(N); do
    [[ $f.zwc -nt $f ]] || zcompile -R -- $f.zwc $f
  done
}

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

### End of Zinit's installer chunk

# _evalcache keeps the output of `<tool> init` commands in a file (see .zshrc)
zinit light mroth/evalcache

# Abbreviations (~6 ms, so no defer). This replaces olets/zsh-abbr (~80 ms).
# Load before the widget plugins below, so that they wrap its widgets.
source $HOME/.config/zsh/abbr.zsh

# If run from Cursor or other agents, load packages synchronously to prevent errors, and also skip using starship & defer
if [[ -n "$CURSOR_AGENT" || -n "$CLAUDECODE" || -n "$OPENCODE" ]]; then
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-history-substring-search
  zinit light zsh-users/zsh-autosuggestions
  zinit light direnv/direnv
else

# Load starship theme
# line 1: `starship` binary as command, from github release
# line 2: starship setup at clone(create init.zsh, completion)
# line 3: pull behavior same as clone, source init.zsh
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

zinit light romkatv/zsh-defer
# By default, zsh-defer runs all precmd hooks (-m) and redraws the prompt (-p)
# after each task. With starship, direnv and mise this adds ~37 ms per task,
# and zsh cannot read keys during that time. These plugins do not change the
# prompt, so do not do this.
# zinit ice wait"0" silent
zsh-defer -mp zinit light mollifier/cd-gitroot

zsh-defer -mp zinit light zsh-users/zsh-syntax-highlighting
zsh-defer -mp zinit light zsh-users/zsh-history-substring-search
# Bind the autosuggestion widgets once, not again at each prompt (~8 ms).
# This is safe because autosuggestions loads after the other widget plugins.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Keep -m here: autosuggestions binds its widgets in a precmd hook.
zsh-defer -p zinit light zsh-users/zsh-autosuggestions

zinit from"gh-r" as"program" mv"direnv* -> direnv" \
    atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' \
    pick"direnv" src="zhook.zsh" for \
        direnv/direnv

# zinit light loiccoyle/zsh-github-copilot
# bindkey '»' zsh_gh_copilot_explain  # bind Option+shift+\ to explain
# bindkey '«' zsh_gh_copilot_suggest  # bind Option+\ to suggest
fi
