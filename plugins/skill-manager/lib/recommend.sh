#!/usr/bin/env bash
# skill-manager — recommend: match project needs against OWNED skills (no vectors).
# Shell builds a compact catalog; the LLM ranks brief↔catalog (orchestration in the command/skill).

# sm_catalog [repo] → compact catalog TSV "<name>\t<description>" of owned skills, sorted by name.
# Cohesive bundle (root SKILL.md) = 1 entry; grab-bag group = per-leaf (same rule as sm_list_skills).
sm_catalog() {
  local repo="${1:-$(sm_skills_repo)}" d name desc
  _sm_skill_dirs "$repo" | while IFS= read -r d; do
    [ -n "$d" ] || continue
    name="$(basename "$d")"
    desc="$(sm_frontmatter_field "$d/SKILL.md" description)"
    printf '%s\t%s\n' "$name" "$desc"
  done | sort
}

# sm_skill_dir <name> [repo] → the skill's source dir (for activation via sm_link). Empty if not found.
sm_skill_dir() {
  local name="$1" repo="${2:-$(sm_skills_repo)}" d
  _sm_skill_dirs "$repo" | while IFS= read -r d; do
    [ -n "$d" ] || continue
    if [ "$(basename "$d")" = "$name" ]; then printf '%s\n' "$d"; break; fi
  done
}
