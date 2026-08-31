#!/usr/bin/env bash
# Waybar "custom/battery-eta" - estimated battery life left (time to empty/full)
BAT="${BAT_SYS:-/sys/class/power_supply/BAT0}"
[ -d "$BAT" ] || BAT="/sys/class/power_supply/BAT1"
[ -d "$BAT" ] || { echo '{"text":""}'; exit 0; }

status=$(tr -d '\n' < "$BAT/status" 2>/dev/null)
capacity=$(tr -d '\n' < "$BAT/capacity" 2>/dev/null)
energy_now=$(tr -d '\n' < "$BAT/energy_now" 2>/dev/null)
energy_full=$(tr -d '\n' < "$BAT/energy_full" 2>/dev/null)
power_now=$(tr -d '\n' < "$BAT/power_now" 2>/dev/null)
: "${energy_now:=0}" "${energy_full:=0}" "${power_now:=0}"

minutes_left() {
    awk -v e="$1" -v p="$2" 'BEGIN{ if (p > 0) printf "%d", (e/p)*60 + 0.5 }'
}

fmt() {
    local m="${1//[^0-9]/}"
    [ -n "$m" ] || { printf -- "--"; return; }
    local h=$((m / 60)) min=$((m % 60))
    if [ "$h" -gt 0 ]; then printf "%dh%02dm" "$h" "$min"; else printf "%dm" "$min"; fi
}

rate=$(awk -v p="$power_now" 'BEGIN{ printf "%.1f", p/1000000 }')

case "$status" in
    Discharging)
        text=$(fmt "$(minutes_left "$energy_now" "$power_now")")
        cls="discharging"
        [ "$power_now" -gt 0 ] || text="--"
        state="until empty"
        ;;
    Charging)
        rem=$((energy_full - energy_now))
        text=$(fmt "$(minutes_left "$rem" "$power_now")")
        cls="charging"
        [ "$power_now" -gt 0 ] || text="--"
        state="until full"
        ;;
    *)
        echo '{"text":""}'
        exit 0
        ;;
esac

[ -n "$capacity" ] && {
    if   [ "$capacity" -le 15 ]; then cls="critical"
    elif [ "$capacity" -le 30 ]; then cls="warning"
    fi
}

tooltip="Battery ETA\n$capacity% · ${rate} W drain\n≈ ${text} ${state}"
printf '{"text":"%s","tooltip":"%s","class":"%s"}' "$text" "$tooltip" "$cls"