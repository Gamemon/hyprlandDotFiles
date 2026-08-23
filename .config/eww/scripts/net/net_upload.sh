#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  net_upload.sh
#  Samples network traffic on a given interface and reports upload usage
#  as a percentage (0–100) of a configured max speed.
# ─────────────────────────────────────────────────────────────────────────────

# 1. Safely find the active default interface
iface=$(ip route | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')

# Guard: If no default route is found, output 0.00 and exit
if [ -z "$iface" ]; then
    echo "0.00"
    exit 0
fi

max_speed=12500000   # 100 Mbps (100*1e6 / 8). Adjust this to match your actual ISP upload plan!

# 2. Extract TX (Transmit) bytes safely.
# Note we use $10 here because upload bytes are the 10th column in /proc/net/dev
tx1=$(cat /proc/net/dev | tr ':' ' ' | awk -v iface="$iface" '$1 == iface {print $10}')
sleep 1
tx2=$(cat /proc/net/dev | tr ':' ' ' | awk -v iface="$iface" '$1 == iface {print $10}')

# Guard: If reading the bytes failed, output 0.00 and exit
if [ -z "$tx1" ] || [ -z "$tx2" ]; then
    echo "0.00"
    exit 0
fi

# 3. Calculate bytes per second
bps=$((tx2 - tx1))

# 4. Calculate percentage and clamp between 0 and 100 using awk
percent=$(awk "BEGIN {
    p = ($bps / $max_speed) * 100;
    if (p > 100) p = 100;
    if (p < 0) p = 0;
    printf \"%.2f\", p
}")

echo "$percent"
