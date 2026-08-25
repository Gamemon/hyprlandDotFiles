#!/bin/bash
# =============================================================================
# Monitor Auto-Switch Script
# Author: escproxy (github: Gamemon)
# Repository: https://github.com/Gamemon/hyprlandDotFiles
# =============================================================================
#
# Periodically checks if an external monitor (DP-1) is connected and
# applies the appropriate monitor configuration. Runs in the background.
# =============================================================================

# Apply the correct monitor layout based on whether DP-1 is connected
apply_monitor_config() {
    if is_dp1_connected; then
        # External monitor connected — mirror laptop display to external
        hyprctl keyword monitor "eDP-1, 2560x1440@120, 0x0, 1"
        hyprctl keyword monitor "DP-1, 2560x1440@165, 0x0, 1, mirror, eDP-1"
    else
        # No external monitor — enable laptop screen only
        hyprctl keyword monitor "eDP-1, 2560x1600@120,0x0,1"
        hyprctl keyword monitor "DP-1, disable"
    fi
}

# Check if the DP-1 external display port is physically connected
is_dp1_connected() {
    for status_file in /sys/class/drm/card*/card*-DP-1/status; do
        if [ -f "$status_file" ]; then
            if grep -q "^connected" "$status_file" 2>/dev/null; then
                return 0  # Found and connected
            fi
        fi
    done
    return 1  # Not connected
}

# Poll every 5 seconds — only reconfigures on state changes
while true; do
    if is_dp1_connected; then
        current_state=0
    else
        current_state=1
    fi

    if [ "$current_state" != "$previous_state" ]; then
        apply_monitor_config
        previous_state=$current_state
    fi

    sleep 5
done