#!/usr/bin/env bash
# skill-aware: when a user names a skill we OWN but haven't activated (dormant), nudge toward
# skill-manager. Active skills are discovered natively, so this only fires for dormant ones,
# and only when the prompt shows intent to *use* a skill (avoids generic-noun false positives).
# Pure helpers here; the UPS hook (hooks/skill-aware.sh) wires stdin/stdout.

# Owned skills that are NOT linked into the global skills dir → dormant (agent doesn't see them).
sm_dormant_skills() {
  local repo="${1:-$(sm_skills_repo)}" g="${2:-$(sm_global_dir)}" d name
  _sm_skill_dirs "$repo" | while IFS= read -r d; do
    [ -n "$d" ] || continue
    name="$(basename "$d")"
    [ -e "$g/$name" ] || printf '%s\n' "$name"   # not linked into global → dormant
  done | sort
}

# Prompt mentions a dormant skill by name AND shows use-intent → echo matched name(s).
# Use-intent gate first (avoids generic-noun false positives like "pdf 만들어줘").
sm_aware_match() {
  local prompt="$1" dormant="$2" name
  printf '%s' "$prompt" | grep -qiE "쓰자|쓸|써[줘봐]|사용|활용|돌려|불러|적용|켜[줘봐]" || return 0
  printf '%s\n' "$dormant" | while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf '%s' "$prompt" | grep -qiE "(^|[^A-Za-z0-9_-])$name([^A-Za-z0-9_-]|\$)" && printf '%s\n' "$name"
  done
}
