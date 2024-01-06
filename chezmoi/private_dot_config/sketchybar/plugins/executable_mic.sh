#!/bin/bash

MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

if [[ $MIC_VOLUME -eq 0 ]]; then
  sketchybar -m --set mic icon= icon.padding_left=8 icon.padding_right=8 label.drawing=off
elif [[ $MIC_VOLUME -gt 0 ]]; then
  sketchybar -m --set mic icon= icon.padding_left=8 icon.padding_right=8 label.drawing=off
fi
