#!/usr/bin/env bash
# skill-manager — place: copy a fetched skill into the central repo under its invocation name.
# Folder name = invocation name (rename). Source-grouping via optional <group>. Global stays flat (link step).

# sm_place <src_skill_dir> <invocation_name> [group] [license_file]  → echoes dest path
sm_place() {
  local src="$1" inv="$2" group="${3:-}" lic="${4:-}"
  case "$inv" in ""|*[!a-z0-9-]*) sm_die "invalid invocation name: '$inv'"; return 1;; esac
  if [ -n "$group" ]; then
    case "$group" in *[!a-z0-9-]*) sm_die "invalid group: '$group'"; return 1;; esac
  fi
  [ -d "$src" ] || { sm_die "src not found: $src"; return 1; }
  local repo dest
  repo="$(sm_skills_repo)"
  if [ -n "$group" ]; then dest="$repo/$group/$inv"; else dest="$repo/$inv"; fi
  # clean replace (idempotent; prevents the nested-copy accident on pre-existing dest)
  rm -rf "$dest"; mkdir -p "$dest"
  cp -R "$src"/. "$dest"/ 2>/dev/null
  rm -rf "$dest/.git"
  if [ -n "$lic" ] && [ -f "$lic" ] && [ ! -f "$dest/LICENSE" ]; then
    cp "$lic" "$dest/LICENSE"
  fi
  printf '%s\n' "$dest"
}
