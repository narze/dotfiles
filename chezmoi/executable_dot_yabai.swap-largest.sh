#!/bin/bash

current_id=$(yabai -m query --windows --window | jq .id)
largest_id=$(yabai -m query --windows --window largest | jq .id)
recent_id=$(yabai -m query --windows --window recent | jq .id)

if [ "$current_id" = "$largest_id" ]; then
  yabai -m window --swap recent
  yabai -m window --focus "$recent_id"
else
  yabai -m window --focus largest
  yabai -m window --swap "$current_id"
  yabai -m window --focus "$current_id"

  # yabai -m window --swap largest
  # sleep 0.2
  # yabai -m window --focus "$current_id"
fi
