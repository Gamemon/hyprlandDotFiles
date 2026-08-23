#!/usr/bin/env bash
# ~/.config/eww/scripts/net/net_vpn_status.sh
# Show VPN status + country (for Eww)

if nordvpn status 2>/dev/null | grep -q "Status: Connected"; then
  country=$(nordvpn status 2>/dev/null | grep "Country" | awk -F': ' '{print $2}')
  [[ -z "$country" ]] && country="SECURE"
  echo "$country"
else
  echo "OFFLINE"
fi

