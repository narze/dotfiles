#!/usr/bin/env sh

if [ -n "$INFO" ]; then
  sketchybar --set $NAME label="$INFO" drawing="on"
fi
