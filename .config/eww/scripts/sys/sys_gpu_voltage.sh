#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Reads NVIDIA GPU voltage using nvidia-smi and prints it in millivolts.
# ─────────────────────────────────────────────────────────────────────────────
sensors amdgpu-pci-3500 2>/dev/null | awk '/vddgfx:/ {print $2, $3}' || echo "N/A"
