#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.drawing=on
else
  sketchybar --set $NAME background.drawing=off
fi

# Log into /tmp/aerospace.log
echo "FOCUSED_WORKSPACE: $FOCUSED_WORKSPACE" >>/tmp/aerospace.log
