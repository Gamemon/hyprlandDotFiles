#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  sys_cpu_voltage.sh
#  Reads CPU voltage (in0) from lm-sensors and prints it in volts.
#  Requires: lm-sensors (and sensors-detect configured)
# ─────────────────────────────────────────────────────────────────────────────

sensors BAT0-acpi-0 2>/dev/null | awk '/in0:/ {print $2, $3}' || echo "N/A"
