#!/usr/bin/env bash
RUNNING=$(osascript -e 'if application "Spotify" is running then return 0')
if [ "$RUNNING" == "" ]; then
  RUNNING=1
fi
PLAYING=1
TRACK=""
ALBUM=""
ARTIST=""
if [ "$(osascript -e 'if application "Spotify" is running then tell application "Spotify" to get player state')" == "playing" ]; then
  PLAYING=0
fi
TRACK=$(osascript -e 'tell application "Spotify" to get name of current track')
ARTIST=$(osascript -e 'tell application "Spotify" to get artist of current track')
ALBUM=$(osascript -e 'tell application "Spotify" to get album of current track')

if [ $RUNNING -eq 0 ] && [ $PLAYING -eq 0 ]; then
  if [ "$ARTIST" == "" ]; then
    sketchybar -m --set $NAME label="$TRACK  $ALBUM" icon.font="sketchybar-app-font:Regular:13" icon=":spotify:"
  else
    sketchybar -m --set $NAME label="$TRACK  $ARTIST" icon.font="sketchybar-app-font:Regular:13" icon=":spotify:"
  fi
elif [ $RUNNING -eq 0 ] && [ $PLAYING -eq 1 ]; then
  if [ "$ARTIST" == "" ]; then
    sketchybar -m --set $NAME label="$TRACK  $ALBUM" icon.font="sketchybar-app-font:Regular:13" icon=":paused:"
  else
    sketchybar -m --set $NAME label="$TRACK  $ARTIST" icon.font="sketchybar-app-font:Regular:13" icon=":paused:"
  fi
else
  sketchybar -m --set $NAME drawing="off"
fi
