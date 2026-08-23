#!/usr/bin/env bash

while true; do
    # 1. Run your existing generator (hide any standard output)
    bash ~/.config/eww/scripts/ascii/ascii_core_layout.sh > /dev/null

    # 2. Read the temp file and wrap the entire multi-line string into JSON
    # jq -R (raw input) -s (slurp entire file) -c (compact one-line output)
    jq -R -s -c '{content: .}' < /tmp/core_layout.txt

    # 3. Wait 1 second (your old polling interval)
    sleep 1
done
