#!/bin/bash
# Catppuccin Mocha themed swaylock: diagonal accent gradient + big clock.
# Self-contained: generates the background with ImageMagick, no screenshot needed.

set -euo pipefail

# Current monitor resolution (drives the generated image size)
read -r SW SH < <(hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
ms = json.load(sys.stdin)
if not ms:
    print('1920 1080'); raise SystemExit
m = ([x for x in ms if x.get('focused')] or [ms[0]])[0]
print(m['width'], m['height'])
")

# Cache the background keyed by resolution (regenerate only when it changes)
CACHE="$HOME/.cache/swaylock-bg.${SW}x${SH}.png"

# --- Catppuccin Mocha palette ---
DIMMED="#1e1e2e"   # Base

if [[ ! -f "$CACHE" ]]; then
    mkdir -p "$(dirname "$CACHE")"
    # Diagonal lavender -> mauve gradient, soft blue glow at the center,
    # then push toward the dark base so the light clock text pops.
    magick -size "${SW}x${SH}" gradient:"#b4befe-#cba6f7" -rotate 25 \
        \( -size "${SW}x${SH}" radial-gradient:"#89b4fa-$DIMMED" \
             -channel A -negate +channel \) \
        -compose screen -composite \
        -fill "$DIMMED" -colorize 62 \
        "$CACHE"
fi

exec swaylock \
    -i "$CACHE" \
    --clock \
    --timestr "%H:%M" \
    --datestr "%A, %e %B" \
    --font "JetBrainsMono Nerd Font" \
    --font-size=180 \
    --effect-vignette=0.4:0.6 \
    --indicator \
    --indicator-radius=240 \
    --indicator-thickness=16 \
    --indicator-idle-visible \
    --fade-in=0.3 \
    --ring-color "#cba6f7" \
    --ring-clear-color "#89b4fa" \
    --ring-ver-color "#a6e3a1" \
    --ring-wrong-color "#f38ba8" \
    --ring-caps-lock-color "#f9e2af" \
    --key-hl-color "#89b4fa" \
    --bs-hl-color "#f38ba8" \
    --inside-color "#1e1e2e" \
    --inside-clear-color "#313244" \
    --inside-ver-color "#313244" \
    --inside-wrong-color "#313244" \
    --inside-caps-lock-color "#45475a" \
    --line-color "#00000000" \
    --separator-color "#00000000" \
    --text-color "#cdd6f4" \
    --text-clear-color "#a6adc8" \
    --text-ver-color "#a6e3a1" \
    --text-wrong-color "#f38ba8" \
    --text-caps-lock-color "#f9e2af"
