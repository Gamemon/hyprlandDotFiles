#!/bin/bash

# Clean logout helper for Hyprland + SDDM.
#
# The goal is to END the session the way SDDM expects so it can redraw its
# greeter, WITHOUT killing the whole user tree.
#
#   - hyprctl dispatch exit        : graceful compositor shutdown -> start-hyprland
#                                    returns 0 -> sddm-helper exits 0 -> SDDM redraws.
#   - SIGTERM the start-hyprland watchdog : its onSignal() handler calls forceQuit()
#                                    (sets "exiting", SIGTERMs the child) then exits 0.
#
# NEVER use `loginctl terminate-user` (or terminate-session) here: logind SIGKILLs the
# entire session scope including sddm-helper, SDDM treats that as a process *crash*
# (exit code 1) and does not restart the greeter -> black screen with a blinking cursor
# (observed 2026-08-28; a reboot was required to recover).

# Find the start-hyprland watchdog process (the parent of the running Hyprland).
hpid="$(pgrep -x Hyprland | head -1)"
spid=""
[ -n "$hpid" ] && spid="$(ps -o ppid= -p "$hpid" | tr -d ' ')"

# 1) Graceful compositor exit first. (Hyprland 0.55+ lua config rejects legacy `hyprctl dispatch exit`.)
hyprctl dispatch "hl.dsp.exit()" 2>/dev/null

# 2) Wait up to ~5s for Hyprland to stop AND the watchdog to exit (returning 0).
for _ in 1 2 3 4 5; do
    hyland_up=""
    pgrep -x Hyprland >/dev/null 2>&1 && hyland_up=1
    watchdog_up=""
    { [ -n "$spid" ] && kill -0 "$spid" 2>/dev/null; } && watchdog_up=1

    if [ -z "$hyland_up" ] && [ -z "$watchdog_up" ]; then
        exit 0
    fi
    sleep 1
done

# 3) Fallback: cleanly tell the watchdog to force-quit. Only if that is gone do we
#    nudge the compositor directly. Never touch sddm-helper or terminate the user.
if [ -n "$spid" ] && kill -0 "$spid" 2>/dev/null; then
    kill -TERM "$spid" 2>/dev/null
elif pgrep -x Hyprland >/dev/null 2>&1; then
    kill -TERM "$(pgrep -x Hyprland | head -1)" 2>/dev/null
fi

exit 0
