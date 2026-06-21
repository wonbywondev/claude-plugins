#!/usr/bin/env bash
# skill-manager — digest: extract body + build digest-generation prompt.
# The 1-2 line purpose-digest TEXT is produced by the agent/companion skill (LLM),
# not by shell. This module supplies the inputs and is the single place a body is read.

# Print the body of a SKILL.md (frontmatter stripped). No frontmatter → whole file.
sm_digest_body() {
  local f="$1"; [ -f "$f" ] || return 0
  awk '
    NR==1 && $0!="---" { plain=1 }
    plain { print; next }
    { if ($0=="---") { d++; next } if (d>=2) print }
  ' "$f"
}

# Build the prompt the agent uses to generate a purpose-digest for dedup.
sm_digest_prompt() {
  local f="$1" name="${2:-}"
  printf 'Summarize the PURPOSE of this Agent Skill in 1-2 short lines (what it does and when to use it), for duplicate-detection. Skill name: %s\n--- SKILL BODY ---\n%s\n' \
    "$name" "$(sm_digest_body "$f")"
}
