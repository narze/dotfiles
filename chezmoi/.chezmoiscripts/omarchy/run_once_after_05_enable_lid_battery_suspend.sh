#!/bin/bash

# Start the timer that suspends a closed laptop on low battery. Runs after
# files are applied so the unit and ~/bin/lid-battery-suspend exist.
set -u

systemctl --user daemon-reload
systemctl --user enable --now lid-battery-suspend.timer
