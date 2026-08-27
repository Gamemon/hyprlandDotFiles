#!/bin/bash
# opencode_status.sh — waybar module: monitor running opencode agents, token usage,
# estimated context remaining, and recent sessions. Outputs JSON (return-type: json).
# OPENCODE_CONTEXT_BUDGET overrides the assumed per-session context size.

DB="/home/escproxy/.local/share/opencode/opencode.db"
ICON="󰚩"
CONTEXT_BUDGET="${OPENCODE_CONTEXT_BUDGET:-200000}"
MIDNIGHT=$(date -d "today 00:00" +%s%3N 2>/dev/null || echo 0)

QUERY() { sqlite3 -separator ' ' "file:$DB?mode=ro" "$1" 2>/dev/null; }

fmt() {
    n="$1"
    if   [ "$n" -ge 1000000 ]; then awk -v x="$n" 'BEGIN{printf "%.1fM", x/1000000}'
    elif [ "$n" -ge 1000     ]; then awk -v x="$n" 'BEGIN{printf "%.0fk", x/1000}'
    else echo "${n:-0}"; fi
}

PROC=$(pgrep -x opencode 2>/dev/null | wc -l)

LAST=$(QUERY "SELECT COALESCE(MAX(time_updated),0) FROM session")
NOW=$(date +%s%3N)

AGE_STR="never"
if [ "$LAST" -gt 0 ]; then
    AGE=$(( (NOW - LAST) / 1000 ))
    if   [ "$AGE" -ge 86400 ]; then AGE_STR="$(( AGE / 86400 ))d"
    elif [ "$AGE" -ge 3600  ]; then AGE_STR="$(( AGE / 3600 ))h"
    elif [ "$AGE" -ge 60    ]; then AGE_STR="$(( AGE / 60 ))m"
    else AGE_STR="${AGE}s"; fi
fi

read -r T_IN T_OUT T_REA T_CACH <<< "$(QUERY "SELECT COALESCE(SUM(tokens_input),0), COALESCE(SUM(tokens_output),0), COALESCE(SUM(tokens_reasoning),0), COALESCE(SUM(tokens_cache_read),0) FROM session WHERE time_updated >= $MIDNIGHT")"

read -r L_IN L_OUT L_REA <<< "$(QUERY "SELECT COALESCE(tokens_input,0), COALESCE(tokens_output,0), COALESCE(tokens_reasoning,0) FROM session WHERE (tokens_input + tokens_output + tokens_reasoning) > 0 ORDER BY time_updated DESC LIMIT 1")"

USED_CTX=$(( L_IN + L_OUT + L_REA ))
LEFT=$(( CONTEXT_BUDGET - USED_CTX )); [ "$LEFT" -lt 0 ] && LEFT=0

COST=$(QUERY "SELECT printf('%.2f', COALESCE(SUM(cost),0)) FROM session")

USED_TODAY=$(( T_IN + T_OUT + T_REA ))

if   [ "$PROC" -gt 0 ]; then TEXT="$ICON $PROC · $(fmt $USED_TODAY)"; CLASS="active"
elif [ "$LAST" -gt 0  ]; then TEXT="$ICON $AGE_STR";                     CLASS="idle"
else TEXT=""; CLASS="idle"; fi

SESSIONS=$(QUERY "SELECT datetime(time_updated/1000,'unixepoch','localtime') || '  ' || substr(title,1,40) || '  \$' || printf('%.2f', cost) FROM session ORDER BY time_updated DESC LIMIT 6")

NL=$'\n'
TOOLTIP="opencode — $PROC agent(s) | last activity: ${AGE_STR} ago"
TOOLTIP="${TOOLTIP}${NL}Usage today: $(fmt $T_IN) in · $(fmt $T_OUT) out · $(fmt $T_REA) reasoning · $(fmt $T_CACH) cache"
TOOLTIP="${TOOLTIP}${NL}Cost: \$$COST (all time) | session context est.: $(fmt $USED_CTX) used · $(fmt $LEFT) left"
if [ -n "$SESSIONS" ]; then
    TOOLTIP="${TOOLTIP}${NL}${NL}Latest sessions:${NL}$SESSIONS"
fi

TOOLTIP=$(printf '%s' "$TOOLTIP" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"%s","class":"%s","tooltip":"%s"}' "$TEXT" "$CLASS" "$TOOLTIP"