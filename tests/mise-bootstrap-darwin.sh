#!/usr/bin/env bash
# Checks that macOS packages come from `mise bootstrap` instead of `brew bundle`.
# The package list is chezmoi/private_dot_config/mise/conf.d/bootstrap-darwin.toml,
# and one run_onchange script applies it.
# Run: tests/mise-bootstrap-darwin.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

conf=chezmoi/private_dot_config/mise/conf.d/bootstrap-darwin.toml
scripts=chezmoi/.chezmoiscripts
runner=$scripts/run_onchange_after_darwin_31-mise-bootstrap-packages.sh.tmpl

command -v mise >/dev/null || { echo "FAIL - mise is not installed"; exit 1; }
[[ -f $conf ]] || { echo "FAIL - $conf does not exist"; exit 1; }

# The package list parses, and mise reads every manager from it.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$conf" "$tmp/mise.toml"
status=$(cd "$tmp" && MISE_TRUSTED_CONFIG_PATHS="$tmp" mise bootstrap packages status 2>&1)
code=$?
check "mise reads the package list" '[[ $code -eq 0 ]]'
# Show why mise failed.
[[ $code -eq 0 ]] || sed 's/^/# /' <<<"$status"
for want in "brew +gh " "brew +lutzifer/homebrew-tap/keyboardSwitcher " \
  "brew-cask +1password " "brew-cask +setapp "; do
  check "status lists $want" 'grep -Eq "^$want" <<<"$status"'
done

# The old brew bundle package scripts are gone.
check "no darwin script runs brew bundle" '! grep -l "brew bundle" "$scripts"/*darwin* >/dev/null'

# One script applies the list, and re-runs when the list changes.
[[ -f $runner ]] || { echo "FAIL - $runner does not exist"; exit 1; }
rendered=$(chezmoi --source chezmoi execute-template <"$runner")
hash=$(shasum -a 256 "$conf" | cut -d' ' -f1)
check "runner applies bootstrap packages" 'grep -q "bootstrap packages apply" <<<"$rendered"'
check "runner holds the package list hash" 'grep -q "$hash" <<<"$rendered"'

# chezmoi deploys the list on macOS only.
check "chezmoi manages the list" \
  'chezmoi --refresh-externals=never --source chezmoi managed -i files | grep -qx ".config/mise/conf.d/bootstrap-darwin.toml"'
check ".chezmoiignore excludes the list off macOS" \
  'awk "/ne .chezmoi.os \"darwin\"/,/end/" chezmoi/.chezmoiignore | grep -qx ".config/mise/conf.d/bootstrap-darwin.toml"'

exit $fail
