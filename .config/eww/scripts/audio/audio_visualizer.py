# ─────────────────────────────────────────────────────────────────────────────
#  °˖* ૮(  • ᴗ ｡)っ🍸  pewdiepie/archdaemon/dionysh shhheersh
#  vers. 1.0
# ─────────────────────────────────────────────────────────────────────────────
#  Reads /tmp/cava.raw and writes an ASCII‑art file that can be shown by eww, 
#  waybar, or any terminal widget. Can run as exec once in hyprland config.
# ─────────────────────────────────────────────────────────────────────────────
#!/usr/bin/env python3
# ─────────────────────────────────────────────────────────────────────────────
#  °˖* ૮(  • ᴗ ｡)っ🍸  pewdiepie/archdaemon/dionysh shhheersh
#  vers. 1.0
# ─────────────────────────────────────────────────────────────────────────────
#  Reads /tmp/cava.raw and writes an ASCII‑art file that can be shown by eww, 
#  waybar, or any terminal widget. Can run as exec once in hyprland config.
# ─────────────────────────────────────────────────────────────────────────────
#!/usr/bin/env python3
import argparse
import os
import sys
import numpy as np

DEFAULT_WIDTH = 64
DEFAULT_HEIGHT = 12
ATTACK_SPEED = 0.6  # Responsiveness when audio spikes
DECAY_SPEED = 0.25  # Fall speed when audio quietens
BLOCKS = [" ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

def spatial_smooth(vals: np.ndarray) -> np.ndarray:
    """Blurs frequency spikes across neighboring bars for fluid waves."""
    kernel = np.array([0.15, 0.7, 0.15])
    return np.convolve(vals, kernel, mode="same")

def render_ascii(bar_heights: np.ndarray, height: int, width: int) -> str:
    """Renders float heights using fractional block characters."""
    grid = [[" " for _ in range(width)] for _ in range(height)]
    for x in range(width):
        h_val = bar_heights[x]
        full_blocks = int(h_val)
        remainder = h_val - full_blocks
        
        for y in range(min(full_blocks, height)):
            grid[height - 1 - y][x] = BLOCKS[-1]
            
        if full_blocks < height and remainder > 0:
            sub_idx = int(remainder * (len(BLOCKS) - 1))
            if sub_idx > 0:
                grid[height - 1 - full_blocks][x] = BLOCKS[sub_idx]
                
    return "\n".join("".join(row) for row in grid) + "\n"

def process_stream(stream, out_path: str, width: int, height: int) -> None:
    if out_path:
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        tmp_path = out_path + ".tmp"

    current_heights = np.zeros(width, dtype=float)
    rolling_peak = 100.0

    # Read line-by-line in real-time driven by CAVA's framerate clock
    for line in stream:
        line = line.strip()
        if not line:
            continue

        parts = [x for x in line.split(";") if x]
        if not parts:
            continue

        try:
            raw_vals = np.array([float(x) for x in parts[:width]], dtype=float)
        except ValueError:
            continue

        if len(raw_vals) < width:
            raw_vals = np.pad(raw_vals, (0, width - len(raw_vals)))

        # Dynamic volume tracking prevents jarring bar scaling
        max_in_frame = np.max(raw_vals)
        rolling_peak = max(rolling_peak * 0.98, max_in_frame, 10.0)

        # Scale raw values to row grid height
        target_heights = np.clip((raw_vals / rolling_peak) * height, 0, height)
        target_heights = spatial_smooth(target_heights)

        # Apply Attack and Decay exponential smoothing
        rising = target_heights > current_heights
        current_heights[rising] += (target_heights[rising] - current_heights[rising]) * ATTACK_SPEED
        current_heights[~rising] += (target_heights[~rising] - current_heights[~rising]) * DECAY_SPEED

        # Check if frame is silent before writing
        if np.max(current_heights) < 0.01:
            # Optional: write empty string once, then stop updating mtime
            pass 
        else:
            with open(tmp_path, "w") as f:
                f.write(output)
            os.replace(tmp_path, out_path)
        output = render_ascii(current_heights, height, width)

        if out_path:
            # Write to .tmp first, then replace atomically to prevent flickering
            with open(tmp_path, "w") as f:
                f.write(output)
            os.replace(tmp_path, out_path)
        else:
            sys.stdout.write(output)
            sys.stdout.flush()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cava-path", default="/tmp/cava.raw")
    parser.add_argument("--out-path", default="/tmp/visualizer.txt")
    parser.add_argument("--width", type=int, default=DEFAULT_WIDTH)
    parser.add_argument("--height", type=int, default=DEFAULT_HEIGHT)
    args = parser.parse_args()

    # If piped directly via standard input
    if not sys.stdin.isatty():
        process_stream(sys.stdin, args.out_path, args.width, args.height)
    else:
        # Otherwise keep file stream continuously open
        import time
        while True:
            if os.path.exists(args.cava_path):
                try:
                    with open(args.cava_path, "r") as f:
                        process_stream(f, args.out_path, args.width, args.height)
                except Exception:
                    pass
            time.sleep(0.5)

if __name__ == "__main__":
    main()
