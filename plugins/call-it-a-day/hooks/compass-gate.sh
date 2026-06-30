#!/usr/bin/env bash
# Stop hook — when a project's compass is STALE and the user is NOT stopping, block the
# round-end and tell the agent to re-read context.md and re-sync. Self-releases once compass
# is touched (mtime → fresh). Source-safe: helpers below, main only runs when executed.
_CG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
source "$_CG_DIR/common.sh"   # cad_compass_stale

# User signalling they want to stop? → skip the gate (respect intent).
cg_stop_cue() {
  case "$1" in
    *그만*|*마무리*|*나중에*|*나중*|*중단*|*"오늘 여기"*|*"여기까지"*|*stop*|*"that's all"*|*"thats all"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Pure decision: skip | block.  args: <stop_hook_active> <stale-status> <has_stop_cue:yes|no>
cg_decide() {
  local stop_active="$1" stale="$2" has_cue="$3"
  [ "$stop_active" = "true" ] && { echo skip; return; }   # already triggered this round → no infinite loop
  [ "$has_cue" = "yes" ]      && { echo skip; return; }   # user is stopping → respect intent
  [ "$stale" = "stale" ]      && { echo block; return; }  # code newer than compass → re-sync needed
  echo skip                                               # fresh / no-compass / bad-path → silent
}

# Branch opt-out: <cwd>/.compass-gate-skip lists branch names (one per line) to skip. → 0=skip.
cg_branch_skip() {
  local cwd="$1" branch="$2"
  [ -n "$branch" ] || return 1
  [ -f "$cwd/.compass-gate-skip" ] || return 1
  grep -qxF "$branch" "$cwd/.compass-gate-skip" 2>/dev/null
}

# Last user utterance from the transcript JSONL (best-effort).
cg_last_user_text() {
  local tr="$1"
  [ -f "$tr" ] || return 0
  grep '"type":"user"' "$tr" 2>/dev/null | tail -8 | python3 -c '
import json,sys
last=""
for line in sys.stdin:
    try:
        m=json.loads(line).get("message",{})
        c=m.get("content")
        if m.get("role")=="user" and isinstance(c,str): last=c
    except Exception: pass
print(last)
' 2>/dev/null
}

cg_reason() {
  cat <<'EOF'
[compass-gate] 이 프로젝트의 compass가 stale(코드가 compass/*.md보다 최신)인 채로 턴을 끝내려 한다. 멈추기 전에:
1) compass/context.md를 처음부터 재독하고, 이번 변경과 모순되는 섹션을 전부 나열한 뒤 수정하라.
2) 같은 사실이 여러 섹션에 중복되면 한 곳(SSOT)으로 통합하라 — 중복이 stale의 근본원인.
3) plan.md 상태(✅)·📱 테스트, checklist.md 완료/신규 항목을 동기화하라.
mtime 힌트일 뿐이니 'fresh'가 되더라도 의미적 모순 0인지 직접 재독으로 확인하라.
EOF
}

if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
  INPUT=$(cat)
  stop_active=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')
  cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
  tr=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
  # Branch opt-out (<cwd>/.compass-gate-skip)
  cg_branch_skip "$cwd" "$(git -C "${cwd:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)" && exit 0
  cue=no; cg_stop_cue "$(cg_last_user_text "$tr")" && cue=yes
  stale=$(cad_compass_stale "${cwd:-/nonexistent-xyz}")
  if [ "$(cg_decide "$stop_active" "$stale" "$cue")" = "block" ]; then
    jq -n --arg r "$(cg_reason)" '{decision:"block", reason:$r}'
  fi
  exit 0
fi
