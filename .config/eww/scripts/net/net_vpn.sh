#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  net_vpn.sh
#  Checks if VPN (10.6.0.x) is active, outputs 100 (on) or 0 (off).
#  Example: VPN connected  → 100
#           VPN disconnected → 0
# ─────────────────────────────────────────────────────────────────────────────

if nordvpn status 2>/dev/null | grep -q "Status: Connected"; then
  echo 100
else
  echo 0
fi
