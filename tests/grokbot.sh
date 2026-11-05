#!/usr/bin/env bash
# Checks the dotfiles on grokbot (Debian agent host for Claude Code / T3 Code).
# Run after `chezmoi apply`: tests/grokbot.sh
#
# Shells start from a clean environment, so the result does not depend on the
# shell that runs this test.
set -u
fail=0

ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }

base_env=(env -i HOME="$HOME" USER="$(id -un)" TERM=xterm-256color PATH=/usr/local/bin:/usr/bin:/bin)
# Agent shells: Claude Code / T3 Code start with SHELL=/bin/bash and set CLAUDECODE.
agent_env=("${base_env[@]}" SHELL=/bin/bash CLAUDECODE=1)
# Human shells: a terminal login on grokbot.
human_env=("${base_env[@]}" SHELL=/usr/bin/zsh)

src_dir="$(chezmoi source-path)"

# The config template must render on Debian, where os-release has no ID_LIKE.
if chezmoi execute-template --init --promptString "Debian profile (minimal/homelab/ai-agent)=ai-agent" \
  <"$src_dir/.chezmoi.yaml.tmpl" >/dev/null 2>&1; then
  ok "chezmoi config template renders"
else
  bad "chezmoi config template renders"
fi

# check_shell label, env array name, zsh flags...
check_shell() {
  local label=$1 env_name=$2
  shift 2
  local -n env_ref=$env_name
  local err out
  err=$(mktemp)
  out=$("${env_ref[@]}" zsh "$@" 'command -v direnv; command -v opencode; locale' 2>"$err")
  if [[ -s $err ]]; then
    bad "$label: no errors on stderr"
    sed 's/^/       /' "$err" | head -10
  else
    ok "$label: no errors on stderr"
  fi
  rm -f "$err"
  [[ $* == *-i* ]] || return 0
  grep -q '/direnv$' <<<"$out" && ok "$label: direnv on PATH" || bad "$label: direnv on PATH"
  grep -q '/opencode$' <<<"$out" && ok "$label: opencode on PATH" || bad "$label: opencode on PATH"
}

check_shell "agent zsh (non-interactive)" agent_env -c
check_shell "agent zsh (interactive)" agent_env -i -c
check_shell "human zsh (login)" human_env -l -i -c

exit $fail
