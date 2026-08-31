#!/usr/bin/env bash
# battery-restore: return to balanced profile and restart eye-candy killed by battery-save.
set -u

# Only force balanced on AC; on battery the battery-power watcher holds power-saver.
[ "$(cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo 1)" = "1" ] \
    && powerprofilesctl set balanced 2>/dev/null || true

if ! pgrep -f "linux-wallpaper[-_]?engine" >/dev/null 2>&1; then
    nohup linux-wallpaper-engine --no-fullscreen-pause >/dev/null 2>&1 &
fi

if [ -x "$HOME/.config/eww/scripts/launch_hud.sh" ]; then
    nohup "$HOME/.config/eww/scripts/launch_hud.sh" >/dev/null 2>&1 &
fi

if ! pgrep -x cava >/dev/null 2>&1; then
    nohup cava -p "$HOME/.config/cava/config" >/dev/null 2>&1 &
fi

echo "battery-restore: balanced profile + wallpaper/eww/cava/visualizer restored"