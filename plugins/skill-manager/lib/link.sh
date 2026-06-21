#!/usr/bin/env bash
# skill-manager — link: flat per-skill symlink into a scope (global | project:<path>).
# Group folders are NEVER linked whole (CC discovers only one level → must link each leaf).

sm_link_target_dir() {
  case "$1" in
    global)    sm_global_dir ;;
    project:*) printf '%s/.claude/skills' "${1#project:}" ;;
    *)         sm_die "invalid scope: $1"; return 1 ;;
  esac
}

# sm_link <skill_src_dir> <invocation_name> <scope>  → echoes link path
sm_link() {
  local src="$1" inv="$2" scope="$3"
  case "$inv" in ""|*[!a-z0-9-]*) sm_die "invalid invocation name: '$inv'"; return 1;; esac
  [ -d "$src" ] || { sm_die "src not found: $src"; return 1; }
  if [ ! -f "$src/SKILL.md" ]; then
    sm_die "not a skill dir (group folders must be linked per-leaf): $src"; return 1
  fi
  local tdir link
  tdir="$(sm_link_target_dir "$scope")" || return 1
  mkdir -p "$tdir"
  link="$tdir/$inv"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$src" ] && { printf '%s\n' "$link"; return 0; }   # idempotent
    sm_die "link collision: $link already points elsewhere"; return 1
  elif [ -e "$link" ]; then
    sm_die "link collision (non-symlink exists): $link"; return 1
  fi
  ln -s "$src" "$link"
  printf '%s\n' "$link"
}
