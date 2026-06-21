#!/usr/bin/env bash
# skill-manager — shared helpers (paths, enumeration, guards)

# ─── Path resolution (env-var override, portable defaults) ───
sm_skills_repo() { echo "${SKILLS_REPO:-$HOME/dev/agent/skills}"; }
sm_global_dir()  { echo "${GLOBAL_SKILLS_DIR:-$HOME/.claude/skills}"; }
# State dir: explicit override > Claude Code's per-plugin data dir (runtime standard) > standard fallback.
sm_home()        { echo "${SKILL_MANAGER_HOME:-${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/skill-manager-wonbywondev-plugins}}"; }

# ─── Skill enumeration ───
# Emit skill DIR paths in a repo (single source for list/catalog/recommend):
#   flat:      <repo>/<skill>/SKILL.md                 → that dir
#   group:     <repo>/<group>/<skill>/SKILL.md         → each leaf dir (group has no SKILL.md)
#   cohesive:  <repo>/<bundle>/SKILL.md (+ children)   → the bundle dir only (do NOT descend; gstack)
# Resolvable SKILL.md only ([ -f ] follows symlinks → dangling excluded). zsh-safe (find, not globs).
_sm_skill_dirs() {
  local repo="${1:-$(sm_skills_repo)}"
  [ -d "$repo" ] || return 0
  local d sub children subs
  children="$(find -L "$repo" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    if [ -f "$d/SKILL.md" ]; then
      printf '%s\n' "$d"                  # flat or cohesive bundle → do not descend
    else
      subs="$(find -L "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"
      while IFS= read -r sub; do
        [ -n "$sub" ] || continue
        [ -f "$sub/SKILL.md" ] && printf '%s\n' "$sub"
      done <<EOF
$subs
EOF
    fi
  done <<EOF
$children
EOF
}

# List installable skill leaf names (sorted).
sm_list_skills() {
  _sm_skill_dirs "${1:-}" | while IFS= read -r d; do [ -n "$d" ] && basename "$d"; done | sort
}

# ─── Logging / guards ───
sm_log() { echo "[skill-manager] $*" >&2; }
sm_die() { echo "[skill-manager] ERROR: $*" >&2; return 1; }
