# Omarchy (Arch) shell integration for zsh.
#
# Port of /usr/share/omarchy/default/bash/{envs,aliases,init,fns/*,completions}.
# Loaded on Omarchy only (see .chezmoiignore) and before the personal
# aliases/functions, so those can still override anything defined here.

# ---------------------------------------------------------------------------
# Environment (default/bash/envs)
# ---------------------------------------------------------------------------
export EDITOR="${EDITOR:-omarchy-launch-editor --inline}"
export SUDO_EDITOR="$EDITOR"
export BROWSER="${BROWSER:-omarchy-launch-browser}"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ---------------------------------------------------------------------------
# Aliases (default/bash/aliases)
# ---------------------------------------------------------------------------
# File system
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'
sff() {
  if [ $# -eq 0 ]; then
    echo "Usage: sff <destination> (e.g. sff host:/tmp/)"
    return 1
  fi
  local file
  file=$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff) &&
    [ -n "$file" ] && scp "$file" "$1"
}

open() { xdg-open "$@" >/dev/null 2>&1 & }

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias a='omarchy-agent --inline'
alias c='opencode --auto'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
alias cy='codex --approve-for-me'
alias d='docker'
alias r='rails'
alias t='tmux attach || tmux new -s Work'
alias h='herdr'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# ---------------------------------------------------------------------------
# Functions (default/bash/fns/*)
# ---------------------------------------------------------------------------
# Compression
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

# Write iso file to sd card
iso2sd() {
  if (( $# < 1 )); then
    echo "Usage: iso2sd <input_file> [output_device]"
    echo "Example: iso2sd ~/Downloads/ubuntu-25.04-desktop-amd64.iso /dev/sda"
    return 1
  fi

  local iso="$1"
  local drive="$2"

  if [[ -z $drive ]]; then
    local available_sds=$(lsblk -dpno NAME | grep -E '/dev/sd')

    if [[ -z $available_sds ]]; then
      echo "No SD drives found and no drive specified"
      return 1
    fi

    drive=$(omarchy-drive-select "$available_sds")

    if [[ -z $drive ]]; then
      echo "No drive selected"
      return 1
    fi
  fi

  sudo dd bs=4M status=progress oflag=sync if="$iso" of="$drive"
  sudo eject "$drive"
}

# Format an entire drive for a single partition using exFAT
format-drive() {
  if (( $# != 2 )); then
    echo "Usage: format-drive <device> <name>"
    echo "Example: format-drive /dev/sda 'My Stuff'"
    echo -e "\nAvailable drives:"
    lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
  else
    echo "WARNING: This will completely erase all data on $1 and label it '$2'."
    read -r "confirm?Are you sure you want to continue? (y/N): "

    if [[ $confirm =~ ^[Yy]$ ]]; then
      sudo wipefs -a "$1"
      sudo dd if=/dev/zero of="$1" bs=1M count=100 status=progress
      sudo parted -s "$1" mklabel gpt
      sudo parted -s "$1" mkpart primary 1MiB 100%
      sudo parted -s "$1" set 1 msftdata on

      partition="$([[ $1 == *"nvme"* ]] && echo "${1}p1" || echo "${1}1")"
      sudo partprobe "$1" || true
      sudo udevadm settle || true

      sudo mkfs.exfat -n "$2" "$partition"

      echo "Drive $1 formatted as exFAT and labeled '$2'."
    fi
  fi
}

# --- Herdr dev layouts -----------------------------------------------------
# Echo a split ratio as a float
# Usage: _herdr_ratio <numerator> <denominator>
_herdr_ratio() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a / b }'
}

# Split a herdr pane and echo the id of the new pane
# Usage: _herdr_split <pane_id> <right|down> <ratio> <cwd>
_herdr_split() {
  herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus |
    jq -r '.result.pane.pane_id'
}

# Create a Herdr Dev Layout with editor, ai, and terminal
# Usage: hdl <c|cx|codex|other_ai> [<second_ai>]
hdl() {
  [[ -z $1 ]] && { echo "Usage: hdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdl."; return 1; }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="${2:-}"

  editor_pane="$HERDR_PANE_ID"

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  _herdr_split "$editor_pane" down 0.85 "$current_dir" >/dev/null
  ai_pane=$(_herdr_split "$editor_pane" right 0.7 "$current_dir")

  if [[ -n $ai2 ]]; then
    ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$current_dir")
    herdr pane run "$ai2_pane" "$ai2" >/dev/null
  fi

  herdr pane run "$ai_pane" "$ai" >/dev/null
  herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
}

# Create a Herdr Dev Square layout with editor, diff watch, terminal, and opencode
# Usage: hds
hds() {
  [[ -n $1 ]] && { echo "Usage: hds"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hds."; return 1; }

  local current_dir="${PWD}"
  local editor_pane diff_pane terminal_pane opencode_pane

  editor_pane="$HERDR_PANE_ID"

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  terminal_pane=$(_herdr_split "$editor_pane" down 0.5 "$current_dir")
  diff_pane=$(_herdr_split "$editor_pane" right 0.5 "$current_dir")
  opencode_pane=$(_herdr_split "$terminal_pane" right 0.5 "$current_dir")

  herdr pane run "$editor_pane" "nvim ." >/dev/null
  herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null
  herdr pane run "$opencode_pane" "opencode" >/dev/null
}

# Create multiple hdl tabs with one per subdirectory in the current directory
# Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]
hdlm() {
  [[ -z $1 ]] && { echo "Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdlm."; return 1; }

  local ai="$1"
  local ai2="${2:-}"
  local base_dir="$PWD"
  local first=true
  local hdl_command

  herdr workspace rename "$HERDR_WORKSPACE_ID" "$(basename "$base_dir")" >/dev/null

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    printf -v hdl_command 'hdl %q' "$ai"
    [[ -n $ai2 ]] && printf -v hdl_command '%s %q' "$hdl_command" "$ai2"

    if $first; then
      printf -v hdl_command 'cd %q && %s' "$dirpath" "$hdl_command"
      herdr pane run "$HERDR_PANE_ID" "$hdl_command" >/dev/null
      first=false
    else
      local pane_id
      pane_id=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$dirpath" --no-focus |
        jq -r '.result.root_pane.pane_id')
      herdr pane run "$pane_id" "$hdl_command" >/dev/null
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane (great for AI)
# Usage: hsl <pane_count> <command>
hsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: hsl <pane_count> <command>"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hsl."; return 1; }

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"
  local -a columns panes

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  local cols=1
  while (( cols * cols < count )); do ((cols++)); done

  columns=("$HERDR_PANE_ID")
  local k
  for (( k = 1; k < cols; k++ )); do
    columns+=("$(_herdr_split "${columns[-1]}" right "$(_herdr_ratio 1 $((cols - k + 1)))" "$current_dir")")
  done

  local col index rows j last
  for (( index = 0; index < cols; index++ )); do
    col="${columns[index]}"
    rows=$(( count / cols ))
    (( index < count % cols )) && (( rows++ ))
    panes+=("$col")
    last="$col"
    for (( j = 1; j < rows; j++ )); do
      last=$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows - j + 1)))" "$current_dir")
      panes+=("$last")
    done
  done

  local pane
  for pane in "${panes[@]}"; do
    herdr pane run "$pane" "$cmd" >/dev/null
  done
}

# --- Rsync-on-change watchers ----------------------------------------------
# rsw starts one in the background, lsw lists, dsw stops
rsw() {
  (( $# != 2 )) && echo "Usage: rsw <source> <destination>" && return 1
  local src="${1%/}" dest="$2"
  # Reuse one SSH connection per login, so 1Password only prompts once.
  local sockets="${XDG_RUNTIME_DIR:-$HOME/.ssh/sockets}"
  mkdir -p "$sockets"
  local rsh="ssh -o ControlMaster=auto -o ControlPath=$sockets/rsw-%r@%h:%p -o ControlPersist=yes"
  setsid --fork env RSYNC_RSH="$rsh" bash -c 'rsync -a "$1/" "$2"; while inotifywait -r -q -e modify,create,delete,move "$1"; do rsync -a "$1/" "$2"; done' rsw-watch "$src" "$dest" >/dev/null 2>&1
  echo "Watching $src -> $dest"
}

lsw() {
  local pid cmd rest found=0
  while read -r pid cmd; do
    rest="${cmd##*rsw-watch }"
    echo "$pid: ${rest% *} -> ${rest##* }"
    found=1
  done < <(pgrep -af 'rsw-watch ')
  (( found )) || echo "No active watches"
}

dsw() {
  local pid found=0
  for pid in $(pgrep -f 'rsw-watch '); do
    kill -- -"$pid" 2>/dev/null && echo "Stopped watch (pid $pid)" && found=1
  done
  (( found )) || echo "No active watches"
}

# --- SSH port forwarding ---------------------------------------------------
fip() {
  (( $# < 2 )) && echo "Usage: fip <host> <port1> [port2] ..." && return 1
  local host="$1"
  shift
  for port in "$@"; do
    ssh -f -N -L "${port}:localhost:${port}" "$host" && echo "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  (( $# == 0 )) && echo "Usage: dip <port1> [port2] ..." && return 1
  for port in "$@"; do
    pkill -f "ssh.*-L ${port}:localhost:${port}" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
  done
}

lip() {
  pgrep -af "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"
}

# --- SSH reconnect ---------------------------------------------------------
# Wrap ssh to clean up the terminal and reconnect when a connection drops.
ssh() {
  local rc started

  started=$SECONDS
  command ssh "$@"
  rc=$?

  [[ -t 1 ]] || return $rc
  _ssh_disarm

  if (( rc != 255 )) || [[ ! -t 0 ]] || ! _ssh_interactive "$@" ||
    (( SECONDS - started < 30 )); then
    return $rc
  fi

  (
    while true; do
      echo "Connection lost. Reconnecting (Ctrl-C to stop)..."
      sleep 2
      command ssh "$@"
      rc=$?
      _ssh_disarm
      (( rc != 255 )) && exit $rc
    done
  )
}

# Disarm mouse tracking (1000/1002/1003, 1006 encoding), focus reporting
# (1004), and the alternate screen (1049), and show the cursor again.
_ssh_disarm() {
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
}

# True for an interactive session: a destination and no remote command.
_ssh_interactive() {
  local value_opts="BbcDEeFIiJLlmOoPpQRSWw"
  local argv=("$@") arg letters i dest="" opts_done=""

  while (($#)); do
    arg="$1"
    shift

    if [[ -z $opts_done && $arg == "--" ]]; then
      opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for ((i = 0; i < ${#letters}; i++)); do
        if [[ $value_opts == *"${letters:i:1}"* ]]; then
          (( i == ${#letters} - 1 )) && shift
          break
        fi
      done
    elif [[ -z $dest ]]; then
      dest="$arg"
    else
      return 1
    fi
  done

  [[ -n $dest ]] || return 1

  local resolved
  resolved=$(command ssh -G "${argv[@]}" 2>/dev/null) || return 1
  ! grep -i '^remotecommand ' <<<"$resolved" | grep -qvi '^remotecommand none$'
}

# --- Tmux dev layouts ------------------------------------------------------
# Create a Tmux Dev Layout with editor, ai, and terminal
# Usage: tdl <c|cx|codex|other_ai> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="$2"

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m

  tmux select-pane -t "$editor_pane"
}

# Create a Tmux Dev Square layout with editor, diff watch, terminal, and opencode
# Usage: tds
tds() {
  [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }

  local current_dir="${PWD}"
  local editor_pane diff_pane terminal_pane opencode_pane

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  terminal_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  opencode_pane=$(tmux split-window -h -p 50 -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')

  tmux send-keys -t "$editor_pane" -l "nvim ."
  tmux send-keys -t "$editor_pane" C-m
  tmux send-keys -t "$diff_pane" -l "hunk diff --watch"
  tmux send-keys -t "$diff_pane" C-m
  tmux send-keys -t "$opencode_pane" -l "opencode"
  tmux send-keys -t "$opencode_pane" C-m

  tmux select-pane -t "$editor_pane"
}

# Create multiple tdl windows with one per subdirectory in the current directory
# Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  local ai="$1"
  local ai2="$2"
  local base_dir="$PWD"
  local first=true

  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      local pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane (great for AI)
# Usage: tsl <pane_count> <command>
tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"
  local -a panes

  tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"

  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    local new_pane
    local split_target="${panes[-1]}"
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[0]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[0]}"
}

# --- Git worktrees ---------------------------------------------------------
# Create a new worktree and branch from within current git directory.
ga() {
  if [[ -z "$1" ]]; then
    echo "Usage: ga [branch name]"
    return 1
  fi

  local branch="$1"
  local base="$(basename "$PWD")"
  local wt_path="../${base}--${branch}"

  git worktree add -b "$branch" "$wt_path"
  mise trust "$wt_path"
  cd "$wt_path"
}

# Remove worktree and branch from within active worktree directory.
gd() {
  if gum confirm "Remove worktree and branch?"; then
    local cwd base branch root worktree

    cwd="$(pwd)"
    worktree="$(basename "$cwd")"

    root="${worktree%%--*}"
    branch="${worktree#*--}"

    if [[ "$root" != "$worktree" ]]; then
      cd "../$root"
      git worktree remove "$cwd" --force || return 1
      git branch -D "$branch"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Completion (default/bash/completions)
# ---------------------------------------------------------------------------
_omarchy_setup_completion() {
  (( ${+_comps} )) || return 0
  command -v omarchy >/dev/null 2>&1 || return 0

  autoload -Uz bashcompinit && bashcompinit

  _omarchy_complete() {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"

    local omarchy_path bin_dir
    omarchy_path=$(command -v omarchy 2>/dev/null) || return 0
    bin_dir=$(dirname -- "$(readlink -f -- "$omarchy_path" 2>/dev/null || printf '%s' "$omarchy_path")")
    [[ -d $bin_dir ]] || return 0

    local prefix="omarchy"
    local i part
    for ((i = 1; i < COMP_CWORD; i++)); do
      part="${COMP_WORDS[i]}"
      [[ -z $part || $part == -* ]] && continue
      prefix+="-$part"
    done

    local -A seen=()
    local candidates=()
    local file basename rest next

    shopt -s nullglob
    for file in "$bin_dir/$prefix"-*; do
      [[ -f $file && -x $file ]] || continue
      basename="${file##*/}"
      rest="${basename#"$prefix"-}"
      next="${rest%%-*}"
      if [[ -n $next && -z ${seen[$next]:-} ]]; then
        seen[$next]=1
        candidates+=("$next")
      fi
    done
    shopt -u nullglob

    if (( COMP_CWORD == 1 )); then
      candidates+=("commands")
    fi

    if [[ ${COMP_WORDS[1]:-} == "commands" ]] && (( COMP_CWORD >= 2 )); then
      candidates+=("--all" "--json" "--markdown" "--check")
    fi

    if (( ${#candidates[@]} > 0 )); then
      local IFS=$'\n'
      COMPREPLY=($(compgen -W "${candidates[*]}" -- "$cur"))
    fi
  }

  complete -o default -F _omarchy_complete omarchy
}

if command -v zsh-defer >/dev/null 2>&1; then
  zsh-defer _omarchy_setup_completion
else
  _omarchy_setup_completion
fi
