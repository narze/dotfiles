# Fast abbreviations: expand a command name on space or Enter, as olets/zsh-abbr
# does with its default settings. zsh-abbr took ~80 ms to load 211 abbreviations
# (after the first prompt, so keys waited) and started subshells at each space.
# This file reads the same file format, one abbreviation per line:
#   abbr NAME="EXPANSION"
# Only regular abbreviations: the whole text left of the cursor must be NAME,
# optionally after "sudo " or leading spaces. Global abbreviations (-g), the
# `abbr` command, reminders and cursor markers are not supported.
# Test: tests/abbr.zsh (in the chezmoi repo)

typeset -gA _abbrs

# Read the abbreviations file into _abbrs (NAME -> EXPANSION).
_abbr_load() {
  emulate -L zsh
  local file=${ABBR_USER_ABBREVIATIONS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh/abbreviations}
  local line word
  local -a words
  _abbrs=()
  [[ -r $file ]] || return 0
  for line in ${(f)"$(<$file)"}; do
    [[ $line == 'abbr '* ]] || continue
    # The first shell word after `abbr` is NAME="EXPANSION"; remove one level of quotes.
    words=(${(z)line#abbr })
    word=${(Q)words[1]}
    [[ $word == ?*=* ]] && _abbrs[${word%%=*}]=${word#*=}
  done
}

# Set REPLY to $1 with its abbreviation expanded. Return 1 if nothing matches.
_abbr_expand_lbuffer() {
  emulate -L zsh
  local rest=$1 prefix=
  while [[ -n $rest ]]; do
    if (( ${+_abbrs[$rest]} )); then
      REPLY=$prefix$_abbrs[$rest]
      return 0
    fi
    case $rest in
      ('sudo '*) prefix+='sudo '; rest=${rest#sudo } ;;
      (' '*)     prefix+=' ';     rest=${rest# } ;;
      (*)        return 1 ;;
    esac
  done
  return 1
}

abbr-expand-and-insert() {
  local REPLY
  _abbr_expand_lbuffer "$LBUFFER" && LBUFFER=$REPLY
  zle self-insert
}

abbr-expand-and-accept() {
  local REPLY
  # Like zsh-abbr: a line that ends in a space is run as it is.
  if [[ $LBUFFER != *[[:space:]] ]] && _abbr_expand_lbuffer "$LBUFFER"; then
    LBUFFER=$REPLY
  fi
  zle _abbr_accept_line
}

_abbr_load

zle -N abbr-expand-and-insert
zle -N abbr-expand-and-accept
# Keep an accept-line that another plugin defined before this file.
if [[ $widgets[accept-line] == user:* ]]; then
  zle -N _abbr_accept_line ${widgets[accept-line]#user:}
else
  zle -A .accept-line _abbr_accept_line
fi
zle -N accept-line abbr-expand-and-accept

# Bind in emacs and viins: .zshrc selects the keymap (bindkey -e) after this file.
for _abbr_keymap in emacs viins; do
  bindkey -M $_abbr_keymap ' ' abbr-expand-and-insert
  bindkey -M $_abbr_keymap '^ ' magic-space
done
unset _abbr_keymap
bindkey -M isearch '^ ' abbr-expand-and-insert
bindkey -M isearch ' ' magic-space
