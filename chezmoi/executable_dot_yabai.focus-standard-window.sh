#!/bin/bash

window_id=$1
window=$(yabai -m query --windows --window "$window_id")
window_subrole=$(echo "$window" | jq -r '.subrole')

if [ "$window_subrole" = "AXStandardWindow" ]; then
  # If window is not named Picture in Picture
  if [ "$(echo "$window" | jq -r '.title')" != "Picture in Picture" ]; then
    echo focus standard window $window_id >>/tmp/yabai.txt
    yabai -m window --focus "$window_id"
  fi
fi
