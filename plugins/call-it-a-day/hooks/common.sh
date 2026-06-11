#!/usr/bin/env bash
# call-it-a-day — shared helpers / paths. Sourced by hooks and tests. Do not execute.
# (Logic functions are added test-first; this file holds only paths/config.)

CALL_IT_A_DAY_HOME="${CALL_IT_A_DAY_HOME:-$HOME/.claude/call-it-a-day}"
VAULT="${CALL_IT_A_DAY_VAULT:-$HOME/dev/wikis/wiki_claude}"
CAD_MARKER="$CALL_IT_A_DAY_HOME/day-marker"

# Classify a user prompt: "morning" (day start), "wrap" (day end), or "none".
# Wrap requires a full phrase (not the bare word 마무리) to avoid false positives.
cad_classify() {
  local text="$1"
  case "$text" in
    *"좋은 아침"*) echo "morning"; return ;;
  esac
  case "$text" in
    *"마무리하자"*|*"하루 마무리"*|*"여기서 마무리"*) echo "wrap"; return ;;
  esac
  echo "none"
}

# Day marker: a single file recording the start of the current workday.
cad_marker_active() { [ -f "$CAD_MARKER" ]; }

# Start a day. Fresh → "started". Already active (prev day unwrapped) → "carryover" (kept).
cad_marker_start() {
  if [ -f "$CAD_MARKER" ]; then echo "carryover"; return 0; fi
  mkdir -p "$(dirname "$CAD_MARKER")"
  printf '%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$PWD" > "$CAD_MARKER"
  echo "started"
}

# Echo the recorded start timestamp (empty if no active day).
cad_marker_started_at() { [ -f "$CAD_MARKER" ] && cut -f1 "$CAD_MARKER"; }

# End the day (remove marker).
cad_marker_clear() { rm -f "$CAD_MARKER"; }

# mtime (epoch) of a file — macOS (BSD) then Linux (GNU) fallback.
_cad_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }

# Is a project's compass stale (any source file newer than newest compass/*.md)?
# → "stale" | "fresh" | "no-compass". Ignores compass/, .git/, node_modules/.
cad_compass_stale() {
  local proj="$1" f m nc=0 ns=0
  [ -d "$proj/compass" ] || { echo "no-compass"; return; }
  for f in "$proj"/compass/*.md; do
    [ -f "$f" ] || continue
    m=$(_cad_mtime "$f"); [ "${m:-0}" -gt "$nc" ] && nc=$m
  done
  [ "$nc" -eq 0 ] && { echo "no-compass"; return; }
  while IFS= read -r f; do
    m=$(_cad_mtime "$f"); [ "${m:-0}" -gt "$ns" ] && ns=$m
  done < <(find "$proj" -type f -not -path "*/compass/*" -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null)
  if [ "$ns" -gt "$nc" ]; then echo "stale"; else echo "fresh"; fi
}
