#!/bin/bash

# Install and start the Kanata systemd service. Runs once, after files are
# applied so that ~/.config/kanata/kanata.kbd exists.
set -u

if ! command -v kanata >/dev/null 2>&1; then
  echo "kanata is not installed, skipping service setup."
  exit 0
fi

KANATA_BIN="$(command -v kanata)"
KANATA_CFG="${HOME}/.config/kanata/kanata.kbd"

if [ ! -f "$KANATA_CFG" ]; then
  echo "kanata config not found at ${KANATA_CFG}, skipping service setup."
  exit 0
fi

sudo tee /etc/systemd/system/kanata.service >/dev/null <<EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Type=simple
ExecStart=${KANATA_BIN} --cfg ${KANATA_CFG} --no-wait
Restart=always
RestartSec=3
Nice=-20
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now kanata.service
