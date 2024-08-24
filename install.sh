#!/bin/sh

# Ref. https://github.com/twpayne/dotfiles/blob/master/install.sh

# -e: exit on error
# -u: exit on unset variables
set -eu

# Handle Coder environment
# Context: It will run every time Coder workspace restarts, while everything in home directory and chezmoi state is persistent, but system apps are not e.g. zsh, .
if [ -n "${CODER:-}" ]; then
  echo "CODER env detected, symlinking ~/.local/share/chezmoi to ~/.config/coderv2/dotfiles"
  mkdir -p ~/.local/share
  # Link ~/.local/share/chezmoi -> ~/.config/coderv2/dotfiles
  ln -sf ~/.config/coderv2/dotfiles ~/.local/share/chezmoi

  # Install zsh if not installed and non-interactive shell, then change default shell for all users
  if ! command -v zsh >/dev/null; then
    sudo apt-get install -y zsh
  fi

  # change default shell for current user
  sudo chsh -s "$(which zsh)" "$USER"

  # if chezmoi already exists at ~/.local/bin/chezmoi, clear script state so that scripts are re-run
  if [ -f ~/.local/bin/chezmoi ]; then
    ~/.local/bin/chezmoi state delete-bucket --bucket=scriptState
  fi
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

if [ -n "${CODER:-}" ]; then
  set -- init --apply --source="${script_dir}" -k -x encrypted --force
fi

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
