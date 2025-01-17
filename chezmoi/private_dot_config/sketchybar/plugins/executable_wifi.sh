#!/usr/bin/env sh

# Stops working on Sonoma
# CURRENT_WIFI="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I)"
# SSID="$(echo "$CURRENT_WIFI" | grep -o "SSID: .*" | sed 's/^SSID: //')"
# CURR_TX="$(echo "$CURRENT_WIFI" | grep -o "lastTxRate: .*" | sed 's/^lastTxRate: //')"

SSID="$(ipconfig getsummary "$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')" | awk -F ' SSID : ' '/ SSID : / {print $2}')"

if [ "$SSID" = "" ]; then
  sketchybar --set "$NAME" label="Disconnected" icon=󰖪 label.font.size=10
else
  sketchybar --set "$NAME" label="$SSID" icon= label.font.size=10
fi
