#!/usr/bin/env bash

COMPONENT=$1 # 'cpu' or 'gpu' passed from Eww

# Define your ASCII spinner frames here. 
# Replace these with whatever custom characters your HUD uses.
FRAMES=("|" "/" "-" "\\")
# Braille alternative: FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

NUM_FRAMES=${#FRAMES[@]}
INDEX=0

while true; do
    # Output the current frame
    echo "${FRAMES[$INDEX]}"
    
    # Advance the index, looping back to 0 when it hits the end
    INDEX=$(( (INDEX + 1) % NUM_FRAMES ))
    
    # Wait 200ms (0.2s) before the next frame
    sleep 0.2
done
