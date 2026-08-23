#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_dc_voltage.sh
#  Reads the VDDNB (SoC / NB voltage) from lm-sensors and prints it in mV.
#  Requires: lm-sensors (run `sensors-detect` to configure chip readings).
# ─────────────────────────────────────────────────────────────────────────────

sensors | awk '/vddnb:/ {printf "%s mV\n", $2}' || echo "N/A"

