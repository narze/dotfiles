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
# Without jq the script keeps the file as it is, so these checks need jq.
command -v jq >/dev/null || bad "jq is installed" missing jq
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

# JSON with // comment lines (Zed, VS Code, Cursor). The comments must stay.
jsonc() { python3 -I -c "import json,re,sys; d=json.loads(re.sub(r'(?m)^\s*//.*\n', '', sys.stdin.read())); print($1)"; }

# Zed: "telemetry": { "diagnostics": false, "metrics": false }
zed=chezmoi/private_dot_config/zed/modify_settings.json
in=$'// Zed settings\n{\n  "diagnostics": { "button": true },\n  "theme": "One Dark"\n}\n'
out=$(modify $zed "$in")
eq "zed: telemetry off" "$(jsonc 'd["telemetry"]' <<<"$out")" "{'diagnostics': False, 'metrics': False}"
eq "zed: other keys kept" "$(jsonc 'd["diagnostics"], d["theme"]' <<<"$out")" "{'button': True} One Dark"
eq "zed: comments kept" "$(head -1 <<<"$out")" "// Zed settings"
out=$(modify $zed $'{\n  "telemetry": { "metrics": true },\n  "theme": "x"\n}\n')
eq "zed: one-line object changes to false" "$(jsonc 'd["telemetry"], d["theme"]' <<<"$out")" "{'diagnostics': False, 'metrics': False} x"
out=$(modify $zed $'{\n  "telemetry": {\n    "diagnostics": true,\n    "x": 1\n  },\n  "diagnostics": { "button": true }\n}\n')
eq "zed: multi-line object changes to false" \
  "$(jsonc 'sorted(d["telemetry"].items()), d["diagnostics"]' <<<"$out")" \
  "[('diagnostics', False), ('metrics', False), ('x', 1)] {'button': True}"
common zed $zed "$in"

# VS Code and Cursor: "telemetry.telemetryLevel": "off"
for app in Code Cursor; do
  f="chezmoi/Library/private_Application Support/private_$app/User/modify_settings.json.tmpl"
  in=$'{\n  // editor\n  "editor.fontSize": 14,\n  "telemetry.telemetryLevel": "crash",\n  "x": 1\n}\n'
  out=$(modify "$f" "$in")
  eq "$app: telemetry level off" "$(jsonc 'd["telemetry.telemetryLevel"]' <<<"$out")" off
  eq "$app: other keys kept" "$(jsonc 'd["editor.fontSize"], d["x"]' <<<"$out")" "14 1"
  eq "$app: comments kept" "$(grep -c '// editor' <<<"$out")" 1
  out=$(modify "$f" $'{\n  "editor.fontSize": 14\n}\n')
  eq "$app: missing key added" "$(jsonc 'd["telemetry.telemetryLevel"], d["editor.fontSize"]' <<<"$out")" "off 14"
  common "$app" "$f" "$in"
done

# /etc/hosts: a marked block sends telemetry hosts to 0.0.0.0 and ::.
# HOSTS_FILE and SUDO let the test use a temporary file without root.
hosts_script=chezmoi/.chezmoiscripts/run_after_50-block-telemetry-hosts.sh.tmpl
hosts() {
  chezmoi --source chezmoi execute-template < "$hosts_script" > "$tmp/hosts.sh"
  chmod +x "$tmp/hosts.sh"
  HOSTS_FILE="$tmp/hosts" SUDO= "$tmp/hosts.sh" 2>&1
}
printf '127.0.0.1\tlocalhost\n::1             localhost\n' > "$tmp/hosts"
hosts >/dev/null
eq "hosts: other lines kept" "$(grep -c localhost "$tmp/hosts")" 2
eq "hosts: IPv4 blocked" "$(grep -cx '0.0.0.0 ingest.t3.codes' "$tmp/hosts")" 1
eq "hosts: IPv6 blocked" "$(grep -cx ':: ingest.t3.codes' "$tmp/hosts")" 1
cp "$tmp/hosts" "$tmp/hosts.once"
eq "hosts: second run prints nothing" "$(hosts)" ""
eq "hosts: second run changes nothing" "$(cmp -s "$tmp/hosts" "$tmp/hosts.once" && echo same)" same
printf 'x\n# BEGIN chezmoi: block telemetry hosts\n0.0.0.0 old.example\n# END chezmoi: block telemetry hosts\ny\n' > "$tmp/hosts"
hosts >/dev/null
eq "hosts: old block replaced, not repeated" \
  "$(grep -c old.example "$tmp/hosts") $(grep -c 'BEGIN chezmoi' "$tmp/hosts") $(grep -cx y "$tmp/hosts")" "0 1 1"
eq "hosts: no script on Windows" \
  "$(chezmoi --source chezmoi execute-template --override-data '{"chezmoi":{"os":"windows"}}' < "$hosts_script" | tr -d '[:space:]')" ""

# The Library folder exists only on macOS.
eq "Library is ignored on Linux" \
  "$(chezmoi --source chezmoi execute-template --override-data '{"chezmoi":{"os":"linux","osRelease":{"id":"arch"}}}' < chezmoi/.chezmoiignore | grep -cx Library)" 1
eq "Library is used on macOS" \
  "$(chezmoi --source chezmoi execute-template --override-data '{"chezmoi":{"os":"darwin"}}' < chezmoi/.chezmoiignore | grep -cx Library)" 0

exit $fail
