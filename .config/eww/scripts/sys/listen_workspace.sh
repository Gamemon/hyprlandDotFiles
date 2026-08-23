#!/usr/bin/env bash

# Output the current workspace immediately on startup
hyprctl activeworkspace -j | jq -r '.id'

# Listen to the event socket continuously
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == workspace>>* ]]; then
        # Extract everything after 'workspace>>'
        echo "${line#workspace>>}"
    fi
done
