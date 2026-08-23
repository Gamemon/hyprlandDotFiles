#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  ascii_core_layout.sh
#  Gets the current Hyprland workspace ID and writes a small ASCII frame
#  to /tmp/core_layout.txt.
#  Example output (written to /tmp/core_layout.txt):
#                   ─┐     ┌─
#                    [  2  ]
#                   ─┘     └─
# ─────────────────────────────────────────────────────────────────────────────

ws=$(hyprctl activeworkspace -j | jq -r '.id')

cat <<EOF > /tmp/core_layout.txt
                 ─┐     ┌─
                  [  $ws  ]
                 ─┘     └─
EOF
