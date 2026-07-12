---
description: Show skill-manager registry status (installed skills, digests, scope, provenance)
argument-hint: [skill-name]
---

Show skill-manager registry status. Argument (optional skill name): **$ARGUMENTS**

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
source "${CLAUDE_PLUGIN_ROOT}/lib/register.sh"
reg="$(sm_registry_path)"
echo "Registry: $reg"
[ -f "$reg" ] || { echo "(no registry yet)"; exit 0; }
python3 - "$reg" "$ARGUMENTS" <<'PY'
import json,sys
reg=sys.argv[1]; q=sys.argv[2].strip() if len(sys.argv)>2 else ""
d=json.load(open(reg)); skills=d.get("skills",{})
def show(n,e):
    print(f"\n# {n}")
    for k in ("source","source_type","scope","license","upstream_dir","fork_commit","link_mode"):
        if e.get(k): print(f"  {k}: {e[k]}")
    if e.get("digest"): print(f"  digest: {e['digest']}")
if q and q in skills: show(q,skills[q])
else:
    print(f"{len(skills)} skill(s) registered:")
    for n in sorted(skills): print(f"  - {n}  [{skills[n].get('scope','?')}]  {skills[n].get('digest','')[:60]}")
PY
```

Also cross-check: skills in the registry whose symlink is missing or dangling, and skills in `SKILLS_REPO` not yet registered (candidates for lazy digest backfill).

## Routing ledger 위생 (sm_routing_lint)

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/routing.sh"
sm_routing_lint "$(sm_skills_repo)/ROUTING.md" "$(sm_skills_repo)" "call-it-a-day,serena,humanize-korean"
```

- 출력: `missing:<이름>`(원장에 있는데 스킬 실물 없음 — 리네임/제거 시 원장 부패) / `single:<행>`(이름 1개짜리 행 = 재설명, 행 자격 위반). **빈 출력 = clean.**
- extra 목록(셋째 인자) = repo 밖에 사는 플러그인 스킬들. 새 플러그인 스킬을 원장에 등재하면 여기도 추가.

## 사용 통계 (sm_usage)

호출 빈도/최근 사용을 transcript에서 집계해 함께 보여준다 — **활성 스킬의 토큰 위생** 참고용.

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/usage.sh"
echo "# Skill 호출 통계 (telemetry DB 우선, 없으면 transcript 스캔 폴백)"
sm_usage_auto | head -25   # skill <TAB> count <TAB> last_used
echo "# 활성(글로벌 링크)인데 호출 0 — 매 세션 description 토큰 상주 중:"
used="$(sm_usage_auto | cut -f1)"
for d in "$(sm_global_dir)"/*; do n="$(basename "$d")"; printf '%s\n' "$used" | grep -qx "$n" || echo "  $n"; done
```

- **1차 소스 = `~/dev/agent/data/claude-code-toolcalls.db`**(멱등 증분 임포트, 즉답) — **read-only 소비**(SELECT만, `mode=ro`). DB의 쓰기 주체는 임포터뿐(스키마 계약: `~/dev/agent/data/README.md`) — skill-manager는 절대 write하지 않는다. DB는 사후 일괄 임포트라 최신 세션 몇 개는 누락될 수 있음(그 정밀도가 필요하면 `sm_usage`(jsonl 풀스캔)).

- **호출 0의 의미 분리**: ① 진짜 미사용(강등하면 토큰 절약) vs ② 상황 대기(gpt-taste·스타일 variant·geo-audit 등 — 그 상황 오면 씀). dormant 스킬은 항상 0(비활성이라) → 통계로 판단하지 말 것.
- ⚠ **강등은 자동 제안·실행하지 않는다.** 통계는 *정보 제공만*. 활성→dormant 강등은 **사용자가 "스킬 정리하자"고 요청할 때만** 함께 논의·결정한다(되돌리기 쉬운 심링크지만 사용자 주도).
