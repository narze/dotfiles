#!/usr/bin/env zsh
# Checks chezmoi/private_dot_config/zsh/abbr.zsh, the fast abbreviation expander.
# If olets/zsh-abbr is installed (zinit), it also checks that both give the same
# result for each abbreviation in the committed file.
# Run: tests/abbr.zsh
emulate -L zsh
cd ${0:A:h}/.. || exit 1
integer fail=0
ok()  { print -r -- "ok   - $1" }
bad() { print -r -- "FAIL - $1 (got '$2', want '$3')"; fail=1 }
eq()  { if [[ $2 == $3 ]]; then ok $1; else bad $1 $2 $3; fi }

src=$PWD/chezmoi/private_dot_config/zsh/abbr.zsh
file=$PWD/chezmoi/private_dot_config/zsh/abbreviations
tmp=$(mktemp -d)
trap 'rm -rf $tmp' EXIT

# Prints the new left buffer for $2, or NONE, with the abbreviations in file $1.
expand_with() {
  ABBR_USER_ABBREVIATIONS_FILE=$1 zsh -f -i -c '
    source $0 2>&1 || exit 1
    local REPLY
    _abbr_expand_lbuffer $1 && print -r -- $REPLY || print -r -- NONE' $src $2 2>&1
}

# 1. Expansion rules, with a small file
cat > $tmp/abbreviations <<'EOF'
abbr gst="git status"
abbr -="cd -"
abbr .tmux="\$EDITOR ~/.tmux.conf.local"
abbr glog="git log --pretty=format:'%Cred%h%Creset'"
# abbr off="commented out"
EOF
eq "expands the whole line"           "$(expand_with $tmp/abbreviations gst)"        "git status"
eq "expands after sudo"               "$(expand_with $tmp/abbreviations 'sudo gst')" "sudo git status"
eq "expands after leading spaces"     "$(expand_with $tmp/abbreviations '  gst')"    "  git status"
eq "expands after space and sudo"     "$(expand_with $tmp/abbreviations ' sudo gst')" " sudo git status"
eq "no expansion in argument position" "$(expand_with $tmp/abbreviations 'echo gst')" NONE
eq "no expansion after other words"   "$(expand_with $tmp/abbreviations 'gst x')"    NONE
eq "no expansion of a longer word"    "$(expand_with $tmp/abbreviations gstx)"       NONE
eq "no expansion of an empty line"    "$(expand_with $tmp/abbreviations '')"         NONE
eq "commented lines are ignored"      "$(expand_with $tmp/abbreviations off)"        NONE
eq "name '-' works"                   "$(expand_with $tmp/abbreviations -)"          "cd -"
eq "quotes are removed once"          "$(expand_with $tmp/abbreviations .tmux)"      '$EDITOR ~/.tmux.conf.local'
eq "inner single quotes stay"         "$(expand_with $tmp/abbreviations glog)"       "git log --pretty=format:'%Cred%h%Creset'"
eq "missing file gives no error"      "$(expand_with $tmp/missing gst)"              NONE

# 2. Keys in a real interactive zsh (zpty): space and Enter expand, Ctrl-Space does not
cat > $tmp/e2e <<'EOF'
abbr zzt="print -r -- EXPANDED"
EOF
zmodload zsh/zpty
run_keys() {
  local out line
  zpty -d t 2>/dev/null
  zpty t "ABBR_USER_ABBREVIATIONS_FILE=$tmp/e2e PS1='> ' zsh -f -i"
  zpty -w t "source ${(q)src}; print READY"
  zpty -r t line '*READY*'; zpty -r t line '*> '
  zpty -w -n t "$1"$'\r'
  zpty -r t out '*> '
  zpty -d t
  print -r -- ${${(f)out//$'\r'}[-2]}
}
eq "Enter expands"                       "$(run_keys zzt)"           "EXPANDED"
eq "space expands, then args follow"     "$(run_keys 'zzt x')"       "EXPANDED x"
eq "no expansion in argument position"   "$(run_keys 'print zzt')"   "zzt"
eq "Ctrl-Space is a plain space" \
  "$(ABBR_USER_ABBREVIATIONS_FILE=$tmp/e2e zsh -f -i -c 'source $0; bindkey -M emacs "^ "' $src)" '"^@" magic-space'

# 3. Load time for the committed file. One run can be slow on a busy machine
# (CI runners), so the fastest of 5 runs is compared.
integer ms=999 t
repeat 5; do
  t=$(ABBR_USER_ABBREVIATIONS_FILE=$file zsh -f -i -c '
    zmodload zsh/datetime; t=$EPOCHREALTIME; source $0; print ${$(( (EPOCHREALTIME-t)*1000 ))%.*}' $src)
  (( t < ms )) && ms=t
done
if (( ms < 10 )); then ok "loads the committed file in ${ms} ms"; else bad "load time" "${ms} ms" "< 10 ms"; fi

# 4. Same result as zsh-abbr for each committed abbreviation
zsh_abbr=$HOME/.local/share/zinit/plugins/olets---zsh-abbr/zsh-abbr.zsh
if [[ -f $zsh_abbr ]]; then
  # Prints "name<TAB>expansion" for each name. Uses the public `abbr list-abbreviations`
  # and `abbr expand` commands of zsh-abbr. $0 = 'ref' to use zsh-abbr, else abbr.zsh
  table() {
    ABBR_USER_ABBREVIATIONS_FILE=$file ABBR_TMPDIR=$tmp/abbr-tmp zsh -f -i -c '
      local name REPLY
      if [[ $0 == ref ]]; then
        source $1 >/dev/null 2>&1
        for name in ${(Q)${(f)"$(abbr list-abbreviations)"}}; do
          print -r -- "$name"$'\''\t'\''"$(abbr expand -- $name)"
        done
      else
        source $2
        for name in ${(k)_abbrs}; do
          _abbr_expand_lbuffer $name && print -r -- "$name"$'\''\t'\''"$REPLY"
        done
      fi' $1 $zsh_abbr $src | sort
  }
  table ref > $tmp/ref.tsv
  table new > $tmp/new.tsv
  (( $(wc -l < $tmp/ref.tsv) > 0 )) || bad "zsh-abbr table" empty "some lines"
  eq "same names as zsh-abbr" "$(cut -f1 $tmp/new.tsv | md5)" "$(cut -f1 $tmp/ref.tsv | md5)"
  if diff $tmp/ref.tsv $tmp/new.tsv >/dev/null; then
    ok "same expansions as zsh-abbr ($(wc -l < $tmp/ref.tsv | tr -d ' ') abbreviations)"
  else
    bad "same expansions as zsh-abbr" "$(diff $tmp/ref.tsv $tmp/new.tsv | head -5)" "no diff"
  fi
else
  print -r -- "skip - zsh-abbr is not installed"
fi

exit $fail
