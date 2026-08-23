# ─────────────────────────────────────────────────────────────────────────────
#  Checks whether the ASCII visualizer output file (/tmp/visualizer.txt)
#  is actively updating by comparing MD5 hashes between loops.
#  Outputs simple text.
#  Called by ascii_audio_status window
# ─────────────────────────────────────────────────────────────────────────────
#!/usr/bin/env bash
VIS_FILE="/tmp/visualizer.txt"

if [ ! -s "$VIS_FILE" ]; then
    echo "[ CORE STATUS: ] Standby."
    exit 0
fi

# Get last modification time in epoch seconds
FILE_TIME=$(stat -c %Y "$VIS_FILE" 2>/dev/null || stat -f %m "$VIS_FILE")
NOW=$(date +%s)

# If updated within the last 2 seconds, it's active
if [ $((NOW - FILE_TIME)) -le 2 ]; then
    echo "[ CORE STATUS: ] Generating visuals."
else
    echo "[ CORE STATUS: ] Inactive."
fi
