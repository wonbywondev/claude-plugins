#!/usr/bin/env bash
# UserPromptSubmit hook — when the prompt names a skill we OWN but haven't activated (dormant)
# with use-intent, nudge toward skill-manager. Active skills are found natively → silent there.
_SA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
source "$_SA_DIR/../lib/common.sh"
# shellcheck disable=SC1091
source "$_SA_DIR/../lib/skill_aware.sh"

INPUT=$(cat)
prompt=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -n "$prompt" ] || exit 0

# Cheap gate: no use-intent → skip the dormant scan entirely (most turns).
printf '%s' "$prompt" | grep -qiE "쓰자|쓸|써[줘봐]|사용|활용|돌려|불러|적용|켜[줘봐]" || exit 0

matched=$(sm_aware_match "$prompt" "$(sm_dormant_skills)")
[ -n "$matched" ] || exit 0

names=$(printf '%s' "$matched" | paste -sd, - | sed 's/,/, /g')
printf '[skill-aware] 보유 중이나 비활성(dormant)인 스킬이 언급됨: %s. 이건 글로벌 컨텍스트에 description이 없어 자동 발동되지 않음 → 쓰려면 `skill-manager`로 활성화(`/skill-manager:recommend` 또는 link로 글로벌/프로젝트 심링크). (이미 활성인 스킬은 네이티브로 알아서 발동하니 무관.)\n' "$names"
