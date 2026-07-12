#!/usr/bin/env bash
# routing: deterministic partial-read + hygiene lint for the skill-relationship ledger
# (~/dev/agent/skills/ROUTING.md). The ledger is the SSOT for *relationships*; descriptions
# keep a 1-line runtime branch cache; registry digests hold identity only.
# Ledger format: "## category" sections, entries are blank-line-separated paragraphs,
# skill names in `backticks`, entry qualification = >=2 names (no single-skill re-description).

# sm_skill_base_name <invocation> → strip plugin namespace ("plug:skill" → "skill").
sm_skill_base_name() {
  printf '%s\n' "${1##*:}"
}

# sm_routing_lookup <routing_file> <name...> → print only paragraphs mentioning any name.
# Empty output = no recorded relationship = proceed.
sm_routing_lookup() {
  local file="$1" pat
  shift
  [ -f "$file" ] || return 0
  [ $# -gt 0 ] || return 0
  pat=$(printf '%s|' "$@"); pat="${pat%|}"
  awk -v pat="$pat" 'BEGIN{RS=""; ORS="\n\n"} $0 ~ pat' "$file"
}

# sm_routing_lint <routing_file> <repo> [extra_names_csv] → hygiene report, empty = clean.
#   missing:<name>  — backticked name not a skill dir in repo (nor in extra list; plugin skills go there)
#   single:<head>   — entry with fewer than 2 backticked names (re-description, not a relationship)
sm_routing_lint() {
  local file="$1" repo="$2" extra="${3:-}" avail para names n name head
  [ -f "$file" ] || return 0
  # enumerate via _sm_skill_dirs (flat + group leaves + cohesive roots) — a bare -d check
  # misses group leaves like taste-skill/design-taste-frontend.
  avail=$(_sm_skill_dirs "$repo" | while IFS= read -r d; do [ -n "$d" ] && basename "$d"; done)
  awk 'BEGIN{RS=""; ORS="\x1e"} /^- /' "$file" | while IFS= read -r -d $'\x1e' para; do
    names=$(printf '%s' "$para" | grep -oE '`[^`]+`' | tr -d '`' | sort -u)
    n=$(printf '%s\n' "$names" | grep -c . || true)
    if [ "$n" -lt 2 ]; then
      head=$(printf '%s' "$para" | head -1 | cut -c1-40)
      printf 'single:%s\n' "$head"
    fi
    printf '%s\n' "$names" | while IFS= read -r name; do
      [ -n "$name" ] || continue
      printf '%s\n' "$avail" | grep -qx "$name" && continue
      case ",$extra," in *",$name,"*) continue ;; esac
      printf 'missing:%s\n' "$name"
    done
  done | sort -u
}
