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

exit $fail
