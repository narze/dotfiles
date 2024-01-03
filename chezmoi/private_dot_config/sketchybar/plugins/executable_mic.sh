#!/bin/bash

MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

if [[ $MIC_VOLUME -eq 0 ]]; then
  sketchybar -m --set mic icon=
elif [[ $MIC_VOLUME -gt 0 ]]; then
  sketchybar -m --set mic icon=
fi
