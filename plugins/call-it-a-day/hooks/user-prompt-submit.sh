#!/usr/bin/env bash
# call-it-a-day — UserPromptSubmit hook.
# stdin: hook JSON {prompt:...}. stdout is injected into Claude's context.
# Greeting "좋은 아침" starts a day; "마무리" triggers wrap-up; during an active day,
# a one-line nudge keeps live knowledge capture on.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

input=$(cat 2>/dev/null || true)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)

NUDGE="[call-it-a-day] 인사이트·새 라이브러리·콘솔/CLI 규칙이 나오면 즉시 wiki(knowledge/libraries|console)에 기록하라(구조 규칙대로, 중복 시 갱신·링크)."

case "$(cad_classify "$prompt")" in
  morning)
    cad_marker_start >/dev/null
    echo "[call-it-a-day] 하루 시작(좋은 아침) — 오늘부터 인사이트 라이브 캡처 ON."
    echo "$NUDGE"
    ;;
  wrap)
    echo "[call-it-a-day] 하루 마무리: call-it-a-day 스킬을 호출해 오늘 작업을 정리하라(프로젝트별 일일 로그 + 그날 knowledge 노트 [[링크]] + 건드린 프로젝트 compass 최신성 점검)."
    ;;
  none)
    if cad_marker_active; then echo "$NUDGE"; fi
    ;;
esac
exit 0
