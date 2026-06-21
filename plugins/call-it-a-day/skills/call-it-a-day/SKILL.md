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
> **노트 컨벤션·레이어 분류(DECISION/INSIGHT/knowledge/daily)·캡처 렌즈·포맷은 `wiki-manager` 스킬을 단일 소스로 따른다** (이 스킬은 *언제* 캡처하나의 cadence, wiki-manager가 *어떻게* 쓰나).
> ⚠ **선언만으론 무력하다 — 노트를 신규 작성하거나 승격하기 전 반드시 `Read $WM/SKILL.md`로 컨벤션 본문을 로드한 뒤 그대로 적용한다** (스킬 자동발동·기억·추론에 의존 금지: "마무리"는 wiki-manager를 자동 소환하지 않으므로 본문이 컨텍스트에 없으면 컨벤션을 근사 수행하게 된다).
> `WM` = `$HOME/.claude/skills/wiki-manager` (심링크 깨졌으면 `$HOME/dev/agent/skills/wiki-manager`). 위임 헬퍼 스크립트는 `$WM/scripts/`.

## Vault 레이아웃 (`$CALL_IT_A_DAY_VAULT`, 기본 `~/dev/wikis/wiki_claude`)

- `daily/YYYY-MM-DD-<project>.md` — 일일 로그 (flat 네이밍; 파일명의 `<project>`로 멀티프로젝트 충돌 회피).
- `knowledge/libraries/<lib>.md` — 새 라이브러리 아토믹 노트.
- `knowledge/console/<tool>.md` — 콘솔/CLI 규칙 아토믹 노트.

세부 폴더 구조는 상황에 맞게 조정 가능(에이전트 자율). vault 쓰기는 컨펌 없이 진행(전제: 글로벌 wiki 쓰기 자유).

## 라이브 캡처 규칙 (하루 중 넛지가 가리키는 그 규칙)

인사이트/새 라이브러리/콘솔 규칙을 만나면 **즉시**(한 줄 jot은 바로, **풀 노트 신규작성이면 먼저 `Read $WM/SKILL.md`**):
1. 해당 아토믹 노트 경로 결정 (`knowledge/libraries/<lib>.md` 등).
2. **이미 있으면 새로 만들지 말고 갱신·보강**(중복 방지). 없으면 생성.
3. frontmatter(`tags`) + 한 줄 요지 + 구체 사용법/함정. 관련 노트는 `[[위키링크]]`.
4. 짧게. 나중에 일일 로그가 이 노트를 링크한다.

## 마무리 절차 (트리거: "하루 마무리하자" 등)

0. **인박스 승격** (`wiki-manager` 위임) — **먼저 `Read $WM/SKILL.md`로 레이어·렌즈·포맷 컨벤션을 로드**(이게 없으면 근사 수행됨) → `bash $WM/scripts/wiki-inbox.sh list`로 `INSIGHT/_inbox.md` 후보 확인 → **소크라테스 게이트**(각 후보에 "모순/근거약함/더 일반화?" 되물어 다듬은 것만) → 렌즈로 **DECISION/INSIGHT/knowledge 풀 노트로 승격**(작성·링크) 또는 **폐기**. ⚠ 인박스는 세션 공유라 **이번 세션 후보만** 승격하고, 전체 `clear` 대신 **승격한 줄만 제거**(다른 세션 후보 보존). (없으면 통과.) 컨벤션은 wiki-manager 단일 소스.
1. **그날 건드린 프로젝트 식별** — 현재 컨텍스트(오늘 작업)에서 작업한 프로젝트 디렉토리들을 추린다. 마커는 프로젝트별이므로, 마무리는 **해당 프로젝트의 day만** 정리(다른 프로젝트 마커는 건드리지 않음).
2. **일일 로그** `daily/YYYY-MM-DD-<project>.md` 생성/추가 (건드린 프로젝트마다 한 파일). **날짜 = 그 하루의 시작("좋은 아침") 날짜** — 마커 있으면 `cad_marker_started_at`, 없으면 작업이 일어난 날(자정 넘겨 마무리해도 마무리 시각의 날짜가 아님). 섹션:
   - **한 일** (요약) / **인사이트** / **해결한 버그** / **결정 로그** / **오늘 추가한 knowledge** (`[[링크]]`).
3. **knowledge 링크 연결** — 오늘 라이브 캡처한 노트들을 일일 로그에서 `[[링크]]`.
4. **compass 최신성 점검** — 건드린 각 프로젝트에 대해 `cad_compass_stale <project>` 실행:
   - `stale` → "⚠️ <project> compass 갱신 필요(소스가 compass보다 최신)" 플래그하고 **마무리 전에 갱신 권유**.
   - `no-compass` → compass 미사용 프로젝트(무시 또는 권유).
5. **요약 보고** + 마커 정리(`cad_marker_clear <project>` — 해당 프로젝트만).
6. 기록할 게 없던 하루면 빈 로그를 만들지 말고 그 사실만 보고.

## 엣지

- "좋은 아침" 없이 "마무리" → 마커 없음: 컨텍스트로 당일 추정하거나 범위를 사용자에게 확인.
- 직전 날 미마무리 상태(carryover) → 이전 하루를 먼저 마무리할지 물어본다.

## 헬퍼

`source ${CLAUDE_PLUGIN_ROOT}/hooks/common.sh` 후 `cad_compass_stale`, `cad_marker_*` 사용.
