#!/usr/bin/env bash
# skill-manager — fetch: clone/copy a source, enumerate skill candidates, parse frontmatter.
# Does NOT place anything. Output of sm_fetch_candidates: TSV "<rel_dir>\t<name>\t<description>".

# Extract a YAML frontmatter field (single-line or folded >/|) from a SKILL.md.
sm_frontmatter_field() {
  local file="$1" field="$2"
  [ -f "$file" ] || return 0
  awk -v f="$field" '
    BEGIN { infm=0; cap=0; done=0; val="" }
    {
      if (NR==1) { if ($0=="---") { infm=1; next } else { exit } }
      if (infm && $0=="---") { exit }
      if (!infm || done) next
      if (cap) {
        if ($0 ~ /^[ \t]+[^ \t]/) { s=$0; sub(/^[ \t]+/,"",s); val=val (val?" ":"") s; next }
        else { done=1; next }
      }
      if ($0 ~ ("^" f ":")) {
        l=$0; sub(("^" f ":[ \t]*"),"",l)
        if (l=="" || l==">" || l=="|" || l==">-" || l==">+" || l=="|-" || l=="|+") { cap=1 }
        else { val=l; done=1 }
      }
    }
    END {
      gsub(/^[ \t]+|[ \t]+$/,"",val)
      gsub(/^"|"$/,"",val); gsub(/^\x27|\x27$/,"",val)
      print val
    }
  ' "$file"
}

# True if dir has a resolvable SKILL.md / skill.md (follows symlinks; dangling = false).
_sm_has_skillmd() {
  local x
  for x in "$1/SKILL.md" "$1/skill.md" "$1/Skill.md"; do
    [ -f "$x" ] && return 0
  done
  return 1
}

# Resolve the actual skill file path in a dir (case variants); empty if none/dangling.
_sm_skillmd_path() {
  local x
  for x in "$1/SKILL.md" "$1/skill.md" "$1/Skill.md"; do
    [ -f "$x" ] && { printf '%s' "$x"; return 0; }
  done
  return 1
}

# Emit one candidate TSV line for a skill dir.
_sm_emit_candidate() {
  local d="$1" staged="$2" smd name desc rel
  smd="$(_sm_skillmd_path "$d")" || return 0
  name="$(sm_frontmatter_field "$smd" name)"
  desc="$(sm_frontmatter_field "$smd" description)"
  if [ "$d" = "$staged" ]; then rel="."; else rel="${d#"$staged"/}"; fi
  printf '%s\t%s\t%s\n' "$rel" "$name" "$desc"
}

# Recursive enumeration with the umbrella rule:
#   - dir has SKILL.md AND <2 child-skill dirs  → LEAF skill (children are references; do not recurse)
#   - dir has SKILL.md AND >=2 child-skill dirs → UMBRELLA: dir is a skill AND recurse into children (gstack)
#   - dir has no SKILL.md                        → GROUP: recurse into children (skills/<n>, flat)
# Dangling symlinks excluded (resolvable check). Depth-capped to bound traversal.
_sm_enum_skills() {
  local dir="$1" staged="$2" depth="$3"
  [ "$depth" -gt 4 ] && return 0
  local has_self=0; _sm_has_skillmd "$dir" && has_self=1
  # child dirs via find (zsh `nomatch` errors on empty globs; find is safe in both shells)
  local children child cwith=0
  children="$(find -L "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"
  while IFS= read -r child; do
    [ -n "$child" ] || continue
    _sm_has_skillmd "$child" && cwith=$((cwith + 1))
  done <<EOF
$children
EOF
  if [ "$has_self" = 1 ] && [ "$cwith" -lt 2 ]; then
    _sm_emit_candidate "$dir" "$staged"        # leaf (refs ignored)
    return 0
  fi
  [ "$has_self" = 1 ] && _sm_emit_candidate "$dir" "$staged"   # umbrella root is also a skill
  while IFS= read -r child; do
    [ -n "$child" ] || continue
    _sm_enum_skills "$child" "$staged" $((depth + 1))
  done <<EOF
$children
EOF
}

# Enumerate skill candidates in a staged repo. TSV "<rel>\t<name>\t<desc>", sorted.
# Handles: single root skill, skills/<n>/, flat <n>/, and umbrella (root + sub-skills, e.g. gstack).
sm_fetch_candidates() {
  local staged="$1"
  [ -d "$staged" ] || return 0
  _sm_enum_skills "$staged" "$staged" 0 | sort
}

# Clone (URL) or copy (local path) a source into dest; strip .git.
sm_fetch_clone() {
  local src="$1" dest="$2"
  case "$src" in
    http://*|https://*|git@*|ssh://*|*.git)
      git clone --depth 1 "$src" "$dest" >/dev/null 2>&1 || { sm_die "clone failed: $src"; return 1; } ;;
    *)
      [ -d "$src" ] || { sm_die "local path not found: $src"; return 1; }
      mkdir -p "$dest"; cp -R "$src"/. "$dest"/ 2>/dev/null ;;
  esac
  rm -rf "$dest/.git"
}
