#!/usr/bin/env bash
# battery-power.sh - set power-profiles-daemon profile based on mains vs battery.
# Env overrides: BATTERY_PROFILE_AC, BATTERY_PROFILE_DC
set -u

ADP=/sys/class/power_supply/ADP0
on=$(cat "$ADP/online" 2>/dev/null || echo 1)

if [ "$on" = "1" ]; then
    prof="${BATTERY_PROFILE_AC:-balanced}"
else
    prof="${BATTERY_PROFILE_DC:-power-saver}"
fi

current=$(powerprofilesctl get 2>/dev/null || true)
if [ "$current" != "$prof" ]; then
    powerprofilesctl set "$prof" 2>/dev/null && echo "battery-power: profile -> $prof"
else
    echo "battery-power: already $prof"
fi