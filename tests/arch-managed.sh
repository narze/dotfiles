#!/usr/bin/env bash
# Checks what chezmoi manages on Arch and on Omarchy. chezmoi finds the distro
# from ID in /etc/os-release, so this test reads the real file and skips other
# systems. CI runs it in an Arch container, then again with ID=omarchy.
# Run: tests/arch-managed.sh
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1 (got '$2', want '$3')"; fail=1; }
eq() { if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

id=$(. /etc/os-release 2>/dev/null && echo "${ID:-}")
[[ $id == arch || $id == omarchy ]] || { echo "skip - not Arch or Omarchy (ID=$id)"; exit 0; }
want_omarchy=false
[[ $id == omarchy ]] && want_omarchy=true

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# The config that `chezmoi init` writes, in a temporary place.
chezmoi --source chezmoi execute-template --init < chezmoi/.chezmoi.yaml.tmpl > "$tmp/chezmoi.yaml" || exit 1
cm() { HOME=$tmp/home chezmoi --config "$tmp/chezmoi.yaml" --source chezmoi --destination "$tmp/home" "$@"; }

eq "is_arch is set" "$(cm execute-template '{{ .is_arch }}')" true
eq "is_omarchy is $want_omarchy" "$(cm execute-template '{{ .is_omarchy }}')" "$want_omarchy"

managed=$(cm managed -x encrypted,externals) || exit 1
has() { if grep -qxF "$1" <<<"$managed"; then echo yes; else echo no; fi; }

# Omarchy owns its desktop, terminal and editor config, except the user
# override files in ~/.config/hypr.
omarchy_only=(
  .config/hypr/bindings.lua
  .config/hypr/input.lua
  .config/kanata/kanata.kbd
  .config/hyprshell/config.toml
  .config/zsh/config/00_omarchy.zsh
  bin/quickshell-runtime-cleanup
  .chezmoiscripts/omarchy/00_install_packages.sh
)
owned_by_omarchy=(.config/ghostty .config/nvim)
if $want_omarchy; then
  for f in "${omarchy_only[@]}"; do eq "manages $f" "$(has "$f")" yes; done
  for f in "${owned_by_omarchy[@]}"; do eq "leaves $f to Omarchy" "$(has "$f")" no; done
else
  for f in "${omarchy_only[@]:2}"; do eq "does not manage $f" "$(has "$f")" no; done
  for f in "${owned_by_omarchy[@]}"; do eq "manages $f" "$(has "$f")" yes; done
fi

for f in .config/mise/conf.d/bootstrap-darwin.toml Library .hammerspoon; do
  eq "does not manage macOS $f" "$(has "$f")" no
done

# Every file and script template renders. A dry run writes and runs nothing.
out=$(cm apply --dry-run --force -x encrypted,externals 2>&1)
eq "dry-run apply succeeds" "$?:$out" "0:"

exit $fail
