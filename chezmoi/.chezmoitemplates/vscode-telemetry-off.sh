#!/bin/sh
# chezmoi modify_ script: set "telemetry.telemetryLevel": "off" in a VS Code
# style settings.json (VS Code, Cursor) and keep all other lines and comments.
# Test: tests/telemetry-off.sh
input=$(cat)
# No file (the editor is not installed): print nothing, so chezmoi creates nothing.
[ -z "$input" ] && exit 0
printf '%s\n' "$input" | awk '
  { line[NR] = $0 }
  /^[[:space:]]*"telemetry\.telemetryLevel"[[:space:]]*:/ {
    sub(/:[[:space:]]*"[^"]*"/, ": \"off\"", line[NR]); found = 1
  }
  END {
    for (i = 1; i <= NR; i++) {
      print line[i]
      # No key: add it just after the opening brace of the top-level object.
      if (!found && !added && line[i] ~ /^[[:space:]]*\{[[:space:]]*$/) {
        print "  \"telemetry.telemetryLevel\": \"off\","; added = 1
      }
    }
  }
'
