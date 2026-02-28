#!/bin/bash

if [ -n "$CLAUDE_ENV_FILE" ]; then
  eval "$(mise activate)"
  echo "Mise activated"
  export -p >> "$CLAUDE_ENV_FILE"
fi

exit 0
