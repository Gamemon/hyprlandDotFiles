#!/bin/bash
# =============================================================================
# Eww Refresh Daemon
# Author: escproxy (github: Gamemon)
# Repository: https://github.com/Gamemon/hyprlandDotFiles
# =============================================================================
#
# Continuously updates Eww widgets by refreshing a timestamp variable.
# This forces Eww to re-render and keeps real-time data (like clocks) current.
# =============================================================================

while true; do
  eww update line_refresh=$(date +%s%3N)
  sleep 0.05
done
