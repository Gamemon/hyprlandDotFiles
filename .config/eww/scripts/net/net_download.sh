# ─────────────────────────────────────────────────────────────────────────────
#  net_download.sh
#  Samples network traffic on a given interface and reports download usage
#  as a percentage (0–100) of a configured max speed.
#  
#  Usage: ./net_download.sh
#  Example: output "42" → meaning 42% of max throughput.
#
# ─────────────────────────────────────────────────────────────────────────────
#!/bin/bash

# 1. Safely find the active default interface
iface=$(ip route | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')

# Guard: If no default route is found, output 0.00 and exit
if [ -z "$iface" ]; then
    echo "0.00"
    exit 0
fi

max_speed=12500000   # 100 Mbps (100*1e6 / 8). Adjust this to match your actual ISP plan!

# 2. Extract bytes safely (swaps colons for spaces to ensure clean parsing)
rx1=$(cat /proc/net/dev | tr ':' ' ' | awk -v iface="$iface" '$1 == iface {print $2}')
sleep 1
rx2=$(cat /proc/net/dev | tr ':' ' ' | awk -v iface="$iface" '$1 == iface {print $2}')

# Guard: If reading the bytes failed, output 0.00 and exit
if [ -z "$rx1" ] || [ -z "$rx2" ]; then
    echo "0.00"
    exit 0
fi

# 3. Calculate bytes per second
bps=$((rx2 - rx1))

# 4. Calculate percentage and clamp between 0 and 100 using awk (handles decimals)
percent=$(awk "BEGIN {
    p = ($bps / $max_speed) * 100;
    if (p > 100) p = 100;
    if (p < 0) p = 0;
    printf \"%.2f\", p
}")

echo "$percent"
