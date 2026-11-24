#!/usr/bin/env bash
# Checks that the dotfiles turn off telemetry in CLI tools and apps.
# Run: tests/telemetry-off.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Environment variables from ~/.zshenv, in a clean non-interactive zsh.
mkdir -p "$tmp/zdot"
chezmoi --source chezmoi execute-template < chezmoi/dot_zshenv.tmpl > "$tmp/zdot/.zshenv"
zshenv_var() {
  env -i HOME="$HOME" PATH=/usr/bin:/bin ZDOTDIR="$tmp/zdot" zsh -c "print -r -- \${$1-unset}"
}
while read -r name want; do
  eq "zshenv sets $name" "$(zshenv_var "$name")" "$want"
done <<'EOF'
T3CODE_TELEMETRY_ENABLED false
DISABLE_TELEMETRY 1
DO_NOT_TRACK 1
HOMEBREW_NO_ANALYTICS 1
NEXT_TELEMETRY_DISABLED 1
VERCEL_TELEMETRY_DISABLED 1
WRANGLER_SEND_METRICS false
TURBO_TELEMETRY_DISABLED 1
ASTRO_TELEMETRY_DISABLED 1
NUXT_TELEMETRY_DISABLED 1
EOF

# modify_ scripts get the current file on stdin and print the new file.
# chezmoi renders a .tmpl script first, then runs it with its shebang.
modify() {
  local script="$tmp/modify.$RANDOM"
  if [[ $1 == *.tmpl ]]; then
    chezmoi --source chezmoi execute-template < "$1" > "$script"
  else
    cp "$1" "$script"
  fi
  chmod +x "$script"
  printf '%s' "$2" | "$script"
}
# Prints a Python expression evaluated on the JSON or TOML document on stdin.
json() { python3 -I -c "import json,sys; d=json.load(sys.stdin); print($1)"; }
toml() { python3 -I -c "import tomllib,sys; d=tomllib.loads(sys.stdin.read()); print($1)"; }
# Checks the common rules for every modify_ script: a missing file stays
# missing, and a second run changes nothing.
common() {
  eq "$1: missing file stays missing" "$(modify "$2" '')" ""
  local once; once=$(modify "$2" "$3")
  eq "$1: second run changes nothing" "$(modify "$2" "$once")" "$once"
}

# Gemini CLI: privacy.usageStatisticsEnabled
gemini=chezmoi/dot_gemini/modify_settings.json
in='{"security": {"auth": {"selectedType": "oauth-personal"}}}'
out=$(modify $gemini "$in")
eq "gemini: usage statistics off" "$(json 'd["privacy"]["usageStatisticsEnabled"]' <<<"$out")" False
eq "gemini: other keys kept" "$(json 'd["security"]["auth"]["selectedType"]' <<<"$out")" oauth-personal
eq "gemini: true changes to false" \
  "$(modify $gemini '{"privacy": {"usageStatisticsEnabled": true}}' | json 'd["privacy"]["usageStatisticsEnabled"]')" False
common gemini $gemini "$in"

# Codex: [analytics] enabled = false
codex=chezmoi/dot_codex/modify_private_config.toml
in=$'model = "gpt-5"\n\n[projects."/a"]\ntrust_level = "trusted"\n'
out=$(modify $codex "$in")
eq "codex: analytics off" "$(toml 'd["analytics"]["enabled"]' <<<"$out")" False
eq "codex: other keys kept" "$(toml 'd["model"], d["projects"]["/a"]["trust_level"]' <<<"$out")" "gpt-5 trusted"
out=$(modify $codex $'[analytics]\nenabled = true\n\n[tui]\nx = 1\n')
eq "codex: true changes to false" "$(toml 'd["analytics"], d["tui"]' <<<"$out")" "{'enabled': False} {'x': 1}"
out=$(modify $codex $'[analytics]\n\n[tui]\nx = 1\n')
eq "codex: key added to an empty table" "$(toml 'd["analytics"], d["tui"]' <<<"$out")" "{'enabled': False} {'x': 1}"
common codex $codex "$in"

exit $fail
