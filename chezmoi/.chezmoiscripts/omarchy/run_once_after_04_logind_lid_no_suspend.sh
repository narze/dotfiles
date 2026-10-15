#!/bin/bash

# Keep the laptop running when the lid closes. The lid bindings in
# ~/.config/hypr/bindings.lua lock the session and turn the panel off instead.
set -u

sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/lid-no-suspend.conf >/dev/null <<'CONF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
CONF

# HUP reloads logind config without ending the session.
sudo systemctl kill -s HUP systemd-logind
