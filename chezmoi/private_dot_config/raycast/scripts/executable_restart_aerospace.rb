#!/usr/bin/env ruby

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reload Aerospace
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author narze

# Quit AeroSpace.app and start again
system('pkill -9 AeroSpace')
sleep 0.5
system('open -a AeroSpace')

# Also restart sketchybar
system('brew services restart sketchybar')

# Notify macOS that the app is restarted
system("osascript -e 'display notification \"AeroSpace restarted\" with title \"AeroSpace\"'")
