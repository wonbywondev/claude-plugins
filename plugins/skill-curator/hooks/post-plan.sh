#!/usr/bin/env bash
# skill-curator — Stop hook (post-plan auto-suggestion)
# After a plan is approved, suggests skill curation for the project.
# Must be fast (<50ms) in the common no-op case.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Guard: central repo must exist
[ -d "$SKILLS_REPO" ] || exit 0

# Guard: already offered this session
OFFERED_MARKER=".claude/.skill-curator-offered"
[ -f "$OFFERED_MARKER" ] && exit 0

# Guard: check for recently-modified plan files (within last 120 seconds)
PLAN_FOUND=0
NOW="$(date +%s)"

check_plans() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    local mtime
    if stat -f %m "$f" >/dev/null 2>&1; then
      mtime="$(stat -f %m "$f")"
    else
      mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    fi
    local age=$(( NOW - mtime ))
    if [ "$age" -lt 120 ]; then
      PLAN_FOUND=1
      return 0
    fi
  done
}

check_plans ".claude/plans"
if [ "$PLAN_FOUND" -eq 0 ]; then
  check_plans "$HOME/.claude/plans"
fi

[ "$PLAN_FOUND" -eq 0 ] && exit 0

# Detect stack and match skills
TAGS="$(detect_stack "$PWD")"
[ -z "$TAGS" ] && exit 0

MATCHED="$(match_skills "$TAGS")"
[ -z "$MATCHED" ] && exit 0

# Output suggestion
TAGS_INLINE="$(echo "$TAGS" | tr '\n' ', ' | sed 's/, $//')"
echo "skill-curator: 플랜이 완료되었습니다. 이 프로젝트에 필요한 스킬을 가져올까요?"
echo "감지된 스택: [$TAGS_INLINE]"
echo "추천 스킬:"
while IFS= read -r skill; do
  echo "  - $skill"
done <<< "$MATCHED"
echo "→ /skill-curator:recommend 로 자세히 보기"

# Mark as offered
mkdir -p "$(dirname "$OFFERED_MARKER")"
touch "$OFFERED_MARKER"
