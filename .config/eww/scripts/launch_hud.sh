#!/usr/bin/env bash

# 1. Kill any running Eww instances and wait a second to prevent ghosts
killall -q eww
sleep 1

# 2. Start the Eww daemon in the background
eww daemon &

# Wait half a second for the socket to initialize
sleep 0.5

# 3. Open all HUD windows simultaneously
eww open-many \
  audio_status \
  welcome_text \
  active_workspace \
  orange_workspace \
  four_boxes \
  visualizer_window \
  power-cooling_header_text \
  power_mode_text \
  right_fan_data \
  ascii_decor_frame \
  workspace_window_text \
  net_bars \
  cpu_ram_storage_bars

# right_internet_text was put into net_bars
python3 ~/.config/eww/scripts/audio/audio_visualizer.py --from-file
