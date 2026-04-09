#!/usr/bin/env bash
# skill-curator — SessionStart hook
# Detects project stack and recommends matching skills from central repo.
# Exits silently if: no central repo, already curated, or no matches.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Guard: central repo must exist
[ -d "$SKILLS_REPO" ] || exit 0

# Guard: already curated (project has symlinks in .claude/skills/)
PROJECT_SKILLS="$(project_skills_dir)"
if [ -d "$PROJECT_SKILLS" ]; then
  for entry in "$PROJECT_SKILLS"/*; do
    [ -L "$entry" ] && exit 0
  done
fi

# Detect stack
TAGS="$(detect_stack "$PWD")"
[ -z "$TAGS" ] && exit 0

# Match skills
MATCHED="$(match_skills "$TAGS")"
[ -z "$MATCHED" ] && exit 0

# Output recommendation
TAGS_INLINE="$(echo "$TAGS" | tr '\n' ', ' | sed 's/, $//')"
echo "skill-curator: detected [$TAGS_INLINE] stack"
echo "Recommended skills:"
while IFS= read -r skill; do
  echo "  - $skill"
done <<< "$MATCHED"
echo "Run /skill-curator:recommend for details or /skill-curator:link to install"
