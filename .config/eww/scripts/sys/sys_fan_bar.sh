#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bar_render.sh
#  Renders a simple horizontal bar graph from a percentage value.
#  Example: ./bar_render.sh 75  →  ███████░░░
# ─────────────────────────────────────────────────────────────────────────────

usage=$1  # percent or normalized value
full="█"
empty="░"
blocks=10
filled=$(( usage * blocks / 100 ))
bar=""

for ((i=0; i<blocks; i++)); do
  if [ $i -lt $filled ]; then
    bar+="$full"
  else
    bar+="$empty"
  fi
done

echo "$bar"
