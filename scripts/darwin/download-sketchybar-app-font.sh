#!/bin/bash

# Download sketchybar-app-font, add .ttf to macOS fonts directory,
# and then sketchybar will be able to use the icon font `sketchybar-app-font` and icon format `:icon_name:`
# Also, icon_map function will be available for mapping front application with icon name
# See all available app-icon mappings at ~/.config/sketchybar/plugins/sketchybar-app-font/icon_map_fn.sh

# GitHub user/repo
USER_REPO="kvndrsslr/sketchybar-app-font"

# GitHub API URL for latest release
API_URL="https://api.github.com/repos/$USER_REPO/releases/latest"

# Target directory
TARGET_DIR="$HOME/.config/sketchybar/plugins/sketchybar-app-font"

# File to store the latest version
VERSION_FILE="$TARGET_DIR/VERSION"

# Fonts directory
FONTS_DIR="$HOME/Library/Fonts"

# Create the target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

# Get the latest release version from GitHub API
LATEST_VERSION=$(curl -s $API_URL | grep '"tag_name":' | cut -d '"' -f 4)

# Check if the latest version is available
if [ -z "$LATEST_VERSION" ]; then
  echo "Error: Could not find the latest version."
  exit 1
fi

# Check if the version has changed
if [ -f "$VERSION_FILE" ]; then
  STORED_VERSION=$(<"$VERSION_FILE")
  if [ "$STORED_VERSION" = "$LATEST_VERSION" ]; then
    echo "You already have the latest version of $USER_REPO: $LATEST_VERSION."
    exit 0
  fi
fi

# Update the version file
echo "$LATEST_VERSION" >"$VERSION_FILE"

# Use curl to get the download URLs for all assets in the latest release
DOWNLOAD_URLS=$(curl -s $API_URL | grep "browser_download_url" | cut -d '"' -f 4)

# Check if URLs are found
if [ -z "$DOWNLOAD_URLS" ]; then
  echo "Error: Could not find download URLs."
  exit 1
fi

# Loop over each line (URL) and download the file
while IFS= read -r URL; do
  if [ -n "$URL" ]; then
    FILENAME=$(basename "$URL")
    echo "Downloading $FILENAME..."
    curl -L -o "$TARGET_DIR/$FILENAME" "$URL"
  fi
done <<<"$DOWNLOAD_URLS"

echo "All downloads completed to $TARGET_DIR"

# Copy .ttf files to the Fonts directory
echo "Copying .ttf files to $FONTS_DIR"
find "$TARGET_DIR" -name "*.ttf" -exec cp {} "$FONTS_DIR" \;

echo "Copy completed."
