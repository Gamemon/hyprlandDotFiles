#!/usr/bin/env bash
# battery-save: drop to power-saver profile and stop heavy background eye-candy.
set -u

powerprofilesctl set power-saver 2>/dev/null || true

# Close windows on workspaces 3-5 (music / extra visuals).
# Hyprland 0.55+ (lua config) rejects legacy `hyprctl dispatch closewindow address:X`,
# so use the new lua dispatcher syntax instead.
hyprctl clients -j 2>/dev/null | python3 -c '
import sys, json
for c in json.load(sys.stdin):
    if c["workspace"]["id"] in (3, 4, 5):
        print(c["address"])
' | xargs -r -I{} hyprctl dispatch "hl.dsp.window.close({window = 'address:{}'})" 2>/dev/null

# Wallpaper engine: native renderer + electron GUI
pkill -f "linux-wallpaper[-_]?engine" 2>/dev/null || true
sleep 0.3
pkill -9 -f "linux-wallpaper[-_]?engine" 2>/dev/null || true

# Eww HUD + audio visualizer + cava overlays
pkill -x eww 2>/dev/null || true
pkill -f launch_hud.sh 2>/dev/null || true
pkill -f audio_visualizer.py 2>/dev/null || true
pkill -x cava 2>/dev/null || true

echo "battery-save: power-saver profile + heavy background (wallpaper/eww/cava/visualizer) stopped"