#!/usr/bin/env bash
# battery-power-watch.sh - watch power-source changes and keep the profile in sync.
# Re-applies only when the mains state (ADP0/online) actually changes.
set -u

apply() { "$HOME/.local/bin/battery-power.sh"; }

source_state() { cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo 1; }

last=$(source_state)
apply

if command -v upower >/dev/null 2>&1; then
    upower --monitor | while read -r _line; do
        now=$(source_state)
        if [ "$now" != "$last" ]; then
            apply
            last=$now
        fi
    done
else
    # Fallback: cheap poll if upower is unavailable.
    while :; do
        now=$(source_state)
        if [ "$now" != "$last" ]; then
            apply
            last=$now
        fi
        sleep 30
    done
fi