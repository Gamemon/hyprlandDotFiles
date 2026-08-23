#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  net_ping.sh
#  Measures ICMP ping latency to 1.1.1.1 and outputs the result in milliseconds.
#  If the host is unreachable, prints "0".
#
#  Usage: ./net_ping.sh
#  Example: ./net_ping.sh → 24   (ms)
#
#  Requires: ping (iputils)
# ─────────────────────────────────────────────────────────────────────────────

ping -c 1 -w 2 1.1.1.1 2>/dev/null \
  | grep 'time=' \
  | awk -F'time=' '{print int($2)}' \
  || echo 0

