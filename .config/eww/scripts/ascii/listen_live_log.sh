#!/usr/bin/env bash

while true; do
    bash ~/.config/eww/scripts/ascii/ascii_live_log.sh > /dev/null
    
    # Read the live text file and package it
    jq -R -s -c '{content: .}' < /tmp/live_text.txt
    
    sleep 5
done
