#!/bin/bash

#!/bin/bash

# Read the input sources
input_sources=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources)
layout_name=$(echo "$input_sources" | grep -oE '"KeyboardLayout Name" = [^;]+' | awk -F'= ' '{print $2}' | tr -d '"')
bundle_id=$(echo "$input_sources" | grep -oE '"Bundle ID" = [^;]+' | awk -F'= ' '{print $2}' | tr -d '"')

if [[ -n $layout_name ]]; then
  echo "Current Keyboard Layout: $layout_name"
elif [[ -n $bundle_id ]]; then
  echo "Current Input Source: $bundle_id"
else
  echo "No keyboard layout or input source detected."
fi

# specify short layouts individually.
case "$layout_name" in
  "Colemak DH Matrix") SHORT_LAYOUT="🇺🇸";;
  "Colemak") SHORT_LAYOUT="🇺🇸";;
  "Colemak DHm") SHORT_LAYOUT="🇺🇸";;
  "U.S.") SHORT_LAYOUT="🇺🇸";;
  "Manoonchai") SHORT_LAYOUT="🇹🇭";;
  *) SHORT_LAYOUT="?";;
esac

# If layout_name is empty, then check if bundle_id includes Japanese, then set the flag to 🇯🇵
if [[ -z $layout_name ]]; then
  case "$bundle_id" in
    *"Japanese"*) SHORT_LAYOUT="🇯🇵";;
    *) SHORT_LAYOUT="?";;
  esac
fi

sketchybar --set keyboard label="$SHORT_LAYOUT" icon.drawing="off" label.padding_left=6 label.padding_right=6
