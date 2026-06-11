---
name: call-it-a-day
description: Use when the user wraps up the day ("하루 마무리하자", "오늘 개발 여기서 마무리", "call it a day") to summarize the day's dev work into Obsidian — per-project daily log + atomic knowledge notes (new libraries, console/CLI rules) — and to check compass freshness. Also the reference for how to live-capture insights into the vault during the day.
license: MIT
metadata:
  category: workflow
  locale: ko-KR
---

# call-it-a-day

하루(인사 "좋은 아침" ~ "마무리") 개발을 Obsidian 지식베이스로 정리한다. 두 부분:
- **라이브 캡처**(하루 종일): 인사이트·새 라이브러리·콘솔/CLI 규칙을 *얻는 즉시* vault에 기록.
- **마무리 요약**(마무리 발화 시): 컨텍스트 기반으로 그날 서사를 일일 로그로.

> hook이 day를 감지·마커 관리하고, "마무리" 시 이 스킬을 부른다. 동작 원리는 plugin compass 참조.

## Vault 레이아웃 (`$CALL_IT_A_DAY_VAULT`, 기본 `~/dev/wikis/wiki_claude`)

- `daily/<project>/YYYY-MM-DD.md` — 프로젝트별 일일 로그 (멀티프로젝트 충돌 회피).
- `knowledge/libraries/<lib>.md` — 새 라이브러리 아토믹 노트.
- `knowledge/console/<tool>.md` — 콘솔/CLI 규칙 아토믹 노트.

세부 폴더 구조는 상황에 맞게 조정 가능(에이전트 자율). vault 쓰기는 컨펌 없이 진행(전제: 글로벌 wiki 쓰기 자유).

## 라이브 캡처 규칙 (하루 중 넛지가 가리키는 그 규칙)

인사이트/새 라이브러리/콘솔 규칙을 만나면 **즉시**:
1. 해당 아토믹 노트 경로 결정 (`knowledge/libraries/<lib>.md` 등).
2. **이미 있으면 새로 만들지 말고 갱신·보강**(중복 방지). 없으면 생성.
3. frontmatter(`tags`) + 한 줄 요지 + 구체 사용법/함정. 관련 노트는 `[[위키링크]]`.
4. 짧게. 나중에 일일 로그가 이 노트를 링크한다.

## 마무리 절차 (트리거: "하루 마무리하자" 등)

1. **그날 건드린 프로젝트 식별** — 현재 컨텍스트(오늘 작업)에서 작업한 프로젝트 디렉토리들을 추린다.
2. **프로젝트별 일일 로그** `daily/<project>/YYYY-MM-DD.md` 생성/추가. 섹션:
   - **한 일** (요약) / **인사이트** / **해결한 버그** / **결정 로그** / **오늘 추가한 knowledge** (`[[링크]]`).
3. **knowledge 링크 연결** — 오늘 라이브 캡처한 노트들을 일일 로그에서 `[[링크]]`.
4. **compass 최신성 점검** — 건드린 각 프로젝트에 대해 `cad_compass_stale <project>` 실행:
   - `stale` → "⚠️ <project> compass 갱신 필요(소스가 compass보다 최신)" 플래그하고 **마무리 전에 갱신 권유**.
   - `no-compass` → compass 미사용 프로젝트(무시 또는 권유).
5. **요약 보고** + 마커 정리(`cad_marker_clear`).
6. 기록할 게 없던 하루면 빈 로그를 만들지 말고 그 사실만 보고.

## 엣지

- "좋은 아침" 없이 "마무리" → 마커 없음: 컨텍스트로 당일 추정하거나 범위를 사용자에게 확인.
- 직전 날 미마무리 상태(carryover) → 이전 하루를 먼저 마무리할지 물어본다.

## 헬퍼

`source ${CLAUDE_PLUGIN_ROOT}/hooks/common.sh` 후 `cad_compass_stale`, `cad_marker_*` 사용.
