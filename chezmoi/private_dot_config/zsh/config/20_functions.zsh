zsh_stats() {
  fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n20
}

# nnn
nn() {
  # Block nesting of nnn in subshells
  if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
    echo "nnn is already running"
    return
  fi

  # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
  # To cd on quit only on ^G, remove the "export" as in:
  #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  # NOTE: NNN_TMPFILE is fixed, should not be modified
  export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

  # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
  # stty start undef
  # stty stop undef
  # stty lwrap undef
  # stty lnext undef

  nnn "$@"

  if [ -f "$NNN_TMPFILE" ]; then
    . "$NNN_TMPFILE"
    rm -f "$NNN_TMPFILE" >/dev/null
  fi
}

timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# use_zinit() {
#   cp ~/.zinit_rc ~/.zshrc
#   exec $SHELL -l
# }

use_omz() {
  cp ~/.omz_rc ~/.zshrc
  exec $SHELL -l
}

touch-safe() {
  for f in "$@"; do
    [ -d $f:h ] || mkdir -p $f:h && command touch $f
  done
}

touch-editor() {
  touch-safe $@
  $EDITOR $@
}

take() {
  mkdir -p $@ && cd ${@:$#}
}

n() {
  if [[ -f "$(pwd)/pnpm-lock.yaml" ]]; then
    echo "Found pnpm-lock.yaml, using pnpm"
    pnpm $@
  elif [[ -f "$(pwd)/yarn.lock" ]]; then
    echo "Found yarn.lock, using Yarn"
    yarn $@
  elif [[ -f "$(pwd)/package-lock.json" ]]; then
    echo "Found package-lock.json, using Npm"
    npm $@
  elif [[ -f "$(pwd)/package.json" ]]; then
    echo "No lockfiles found, but found package.json, using pnpm by default"
    pnpm $@
  else
    echo "No lockfiles found"
    return 1
  fi
}

y() {
  n $@
}

function prompt_my_arch_check() {
  local arch=$(uname -m)
  if [[ "$arch" == "arm64" ]]; then
    p10k segment -t "arm" -b 232 -f 7
  elif [[ "$arch" == "x86_64" ]]; then
    p10k segment -t "x86" -b 232 -f 7
  fi
}

music() {
  sh -c "nohup sh -c 'kitty --single-instance --session ~/.config/kitty/sessions/mpd' > /tmp/mpd_nohup.out 2>&1 &"
}

url_encode() {
  awk 'BEGIN {
      for (n = 0; n < 125; n++) {
         m[sprintf("%c", n)] = n
      }
      n = 1
      while (1) {
         s = substr(ARGV[1], n, 1)
         if (s == "") {
            break
         }
         t = s ~ /[[:alnum:]_.!~*\47()-]/ ? t s : t sprintf("%%%02X", m[s])
         n++
      }
      print t
   }' "$1"
}

# Transfer.sh
# Usage : transfer path/to/file
transfer() {
  if [ $# -eq 0 ]; then
    echo "No arguments specified.\nUsage:\n transfer <file|directory>\n ... | transfer <file_name>" >&2
    return 1
  fi

  if tty -s; then
    file="$1"
    file_name=$(basename "$file")
    if [ ! -e "$file" ]; then
      echo "$file: No such file or directory" >&2
      return 1
    fi
    if [ -d "$file" ]; then
      file_name="$file_name.zip" ,
      (cd "$file" && zip -r -q - .) | curl --progress-bar --upload-file "-" "http://transfer.sh/$file_name" | tee /dev/null,
    else cat "$file" | curl --progress-bar --upload-file "-" "http://transfer.sh/$file_name" | tee /dev/null; fi
  else
    file_name=$1
    curl --progress-bar --upload-file "-" "http://transfer.sh/$file_name" | tee /dev/null
  fi
}

dir() {
  basename $PWD
}

shadowenv() {
  # No-op
}

nz_repair_second_brain() {
  if [ -d "$HOME/obsidian/" ]; then
    cd "$HOME/obsidian/"

    if (git status -s); then
      echo "Git is fine"
    else
      echo "Git corrupted, repairing..."
      rm -rf "$HOME/obsidian.git"
      rm -rf /tmp/second-brain
      git clone --no-checkout https://github.com/narze/second-brain.git /tmp/second-brain
      mv /tmp/second-brain/.git "$HOME/obsidian.git"
      git reset
      git status
    fi
  else
    echo "Second brain directory not found"
  fi
}

next_and_current() {
  echo "${fg[green]}================ NEXT ================"
  echo "next $@ ${reset_color}"
  next "$@"

  if [ $? -ne 0 ]; then
    echo "${fg[red]}Next command failed, skipping current command. ${reset_color}"
    return 1
  fi

  echo "\n"
  echo "${fg[green]}================ CURRENT ================"
  echo "$@ ${reset_color}"
  "$@"
}
