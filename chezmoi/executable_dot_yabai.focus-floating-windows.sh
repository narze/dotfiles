#!/bin/bash

window_id=$1
window=$(yabai -m query --windows --window "$window_id")
window_subrole=$(echo "$window" | jq -r '.subrole')
window_is_floating=$(echo "$window" | jq -r '."is-floating"')

# echo "$window_id" >>/tmp/yabai.txt
# echo "$window_subrole" >>/tmp/yabai.txt
# echo "$window_is_floating" >>/tmp/yabai.txt

if [ "$window_subrole" = "AXDialog" ]; then
  if [ "$window_is_floating" = "false" ]; then
    yabai -m window --toggle float --window "$window_id"
    # echo toggle float >>/tmp/yabai.txt
  fi

  # echo toggle focus $window_id >>/tmp/yabai.txt
  yabai -m window --focus "$window_id"
fi
