#!/bin/sh

# Ref. https://github.com/twpayne/dotfiles/blob/master/install.sh

# -e: exit on error
# -u: exit on unset variables
set -eu

# If CODER env is set, then this file will likely to be executed from `coder dotfiles`
# which will clone and run this repo in `~/.config/coderv2/dotfiles`, we don't want that so we'll copy the files to ~/.local/share/chezmoi, then continue
# Also prevents the script from running infinitely
if [ -n "${CODER:-}" ] && [ "${CODER}" != "false" ]; then
  echo "CODER env is set, symlink ~/.local/share/chezmoi to here if not already"
  mkdir -p ~/.local/share
  ln -sf "${PWD}" ~/.local/share/chezmoi

  # Set CODER to false so the script doesn't run infinitely
  export CODER=false
  exec ~/.local/share/chezmoi/install.sh
fi

if ! chezmoi="$(command -v chezmoi)"; then
  bin_dir="${HOME}/.local/bin"
  chezmoi="${bin_dir}/chezmoi"
  echo "Installing chezmoi to '${chezmoi}'" >&2
  if command -v curl >/dev/null; then
    chezmoi_install_script="$(curl -fsSL https://chezmoi.io/get)"
  elif command -v wget >/dev/null; then
    chezmoi_install_script="$(wget -qO- https://chezmoi.io/get)"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
  sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
  unset chezmoi_install_script bin_dir
fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}" -k -x encrypted

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
