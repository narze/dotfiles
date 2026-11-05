#!/bin/bash

# Start the timer that keeps the Omarchy shell from filling the runtime dir.
# Runs after files are applied so the unit and ~/bin/quickshell-runtime-cleanup
# exist.
set -u

systemctl --user daemon-reload
systemctl --user enable --now quickshell-runtime-cleanup.timer
