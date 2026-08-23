#!/usr/bin/env bash
# ~/.config/eww/scripts/net/net_vpn_bar.sh
# Render a 5-line bar directly based on VPN (ipsec) status.

lines=5

if /usr/bin/ipsec statusall 2>/dev/null | grep -q "ESTABLISHED"; then
  # VPN is up → full block bar
  for ((i=0; i<lines; i++)); do
    echo "█"
  done
else
  # VPN is down → thin bar
  for ((i=0; i<lines; i++)); do
    echo "│"
  done
fi

