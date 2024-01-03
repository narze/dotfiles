#!/usr/bin/env bash

if [ -n "$INFO" ]; then
  source "$HOME/.config/sketchybar/plugins/sketchybar-app-font/icon_map_fn.sh"
  icon_map "${INFO}"
  sketchybar --set "$NAME" label="$INFO" drawing="on" icon.font="sketchybar-app-font:Regular:13" icon="$icon_result" icon.drawing="on"
fi
