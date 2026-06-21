#!/usr/bin/env bash
# call-it-a-day — shared helpers / paths. Sourced by hooks and tests. Do not execute.
# (Logic functions are added test-first; this file holds only paths/config.)

# State dir: explicit override > Claude Code's per-plugin data dir (runtime standard) > standard fallback.
CALL_IT_A_DAY_HOME="${CALL_IT_A_DAY_HOME:-${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/call-it-a-day-wonbywondev-plugins}}"
VAULT="${CALL_IT_A_DAY_VAULT:-$HOME/dev/wikis/wiki_claude}"
CAD_MARKERS_DIR="$CALL_IT_A_DAY_HOME/markers"

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

# Per-project day marker. Keyed by project path (default $PWD) so parallel
# projects/sessions each have an independent workday.
_cad_marker_path() { local p="${1:-$PWD}"; echo "$CAD_MARKERS_DIR/${p//\//%2F}"; }

cad_marker_active() { [ -f "$(_cad_marker_path "${1:-$PWD}")" ]; }

# Start a day for the project. Fresh → "started". Already active → "carryover" (kept).
cad_marker_start() {
  local proj="${1:-$PWD}" mp; mp="$(_cad_marker_path "$proj")"
  if [ -f "$mp" ]; then echo "carryover"; return 0; fi
  mkdir -p "$(dirname "$mp")"
  printf '%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$proj" > "$mp"
  echo "started"
}

# Echo the recorded start timestamp for the project (empty if no active day).
cad_marker_started_at() { local mp; mp="$(_cad_marker_path "${1:-$PWD}")"; [ -f "$mp" ] && cut -f1 "$mp"; }

# End the project's day (remove its marker).
cad_marker_clear() { rm -f "$(_cad_marker_path "${1:-$PWD}")"; }

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
