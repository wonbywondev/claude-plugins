#!/usr/bin/env bash
# skill-manager — tool-overlap capability map.
# lib/tools.map (TSV: tool<TAB>keywords<TAB>wiki-note) maps an installed CLI to role keywords,
# so dedup/select can flag a candidate skill that overlaps a tool you already have
# (e.g. imagegen-* ↔ pencil). CLI docs live in the wiki; this only holds keywords + a pointer.

sm_tool_map_path() {
  printf '%s' "${SC_TOOLS_MAP:-${CLAUDE_PLUGIN_ROOT:-}/lib/tools.map}"
}

# Is a tool present? Default = command -v (fast, both shells). npx-only / vendored / skill-backed
# tools won't be detected here (acceptable for v1.1; they rarely overlap-flag).
_sm_tool_installed() { command -v "$1" >/dev/null 2>&1; }

# Collect role keywords for the *installed* tools in the map → deduped CSV.
# Args: [map_file] [installed_csv]
#   map_file     default: sm_tool_map_path
#   installed_csv: if non-empty, membership test against it (deterministic, for tests);
#                  if empty, live-discover via _sm_tool_installed.
sm_installed_tool_keywords() {
  local mapf="${1:-$(sm_tool_map_path)}" installed="${2:-}"
  [ -f "$mapf" ] || return 0
  local tool kw rest out="" tab
  tab="$(printf '\t')"
  while IFS="$tab" read -r tool kw rest; do
    case "$tool" in ''|'#'*) continue;; esac
    if [ -n "$installed" ]; then
      case ",$installed," in *",$tool,"*) : ;; *) continue;; esac
    else
      _sm_tool_installed "$tool" || continue
    fi
    [ -n "$kw" ] && out="${out:+$out,}$kw"
  done < "$mapf"
  # normalize + dedup keywords, re-join with comma
  printf '%s' "$out" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | awk 'NF && !seen[$0]++' | paste -sd ',' -
}
