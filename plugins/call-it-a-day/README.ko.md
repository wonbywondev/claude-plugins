# call-it-a-day

[English](./README.md)

인사로 하루를 구분하고, 그날 개발을 Obsidian 지식베이스로 정리하는 Claude Code 플러그인.
한 세션을 계속 이어가 "새 세션" 훅이 안 먹는 작업 방식을 위한 설계.

## 흐름

- **"좋은 아침"** → 하루 시작(마커 기록). 이후 매 턴 라이브 캡처 넛지 ON.
- **하루 중** → 인사이트·새 라이브러리·콘솔/CLI 규칙을 *얻는 즉시* vault에 기록(컴팩션 손실 방지).
- **"하루 마무리하자" / "오늘 개발 여기서 마무리"** → `call-it-a-day` 스킬이 그날을 정리:
  - 프로젝트별 **일일 로그** `daily/YYYY-MM-DD-<project>.md` (한 일·인사이트·해결한 버그·결정 로그)
  - 그날 추가한 **knowledge 노트** `[[링크]]`
  - 건드린 프로젝트 **compass 최신성 점검**(stale면 갱신 권유)
- **턴 끝(Stop) → compass 정합 게이트** — compass 있는 프로젝트에서 코드를 바꾼 채 끝내려 하면, **stale일 때만**(git-tracked 기준, log/tmp 노이즈 제외) 턴을 되돌려 *context.md 재독·재정합*을 강제(`decision:block`). 무한방지(`stop_hook_active`+8-block cap), 사용자 멈춤 cue("그만/마무리")·`.compass-gate-skip` 브랜치는 스킵. compass 손대면 자동 해제.

## 구조

```
hooks/
  common.sh                 # cad_classify, cad_marker_*, cad_compass_stale(git-tracked), _cad_source_files
  user-prompt-submit.sh     # UserPromptSubmit: 감지→마커/넛지/트리거
  compass-gate.sh           # Stop: stale 시 재정합 강제 (cg_decide/cg_stop_cue/cg_branch_skip)
  hooks.json                # UserPromptSubmit + Stop 등록
skills/call-it-a-day/SKILL.md   # 마무리 절차 + 라이브 캡처 규칙 + compass-gate 재독 지시
test/  run_tests.sh test_*.sh   # bash 하네스 (compass·gate·paths 포함, temp 격리)
```

## Obsidian vault 레이아웃 (`$CALL_IT_A_DAY_VAULT`, 기본 `~/dev/wikis/wiki_claude`)

- `daily/YYYY-MM-DD-<project>.md` — 프로젝트별 일일 로그
- `knowledge/libraries/<lib>.md` — 새 라이브러리
- `knowledge/console/<tool>.md` — 콘솔/CLI 규칙

## 환경 변수

- `CALL_IT_A_DAY_VAULT` — vault 경로 (기본 `~/dev/wikis/wiki_claude`)
- `CALL_IT_A_DAY_HOME` — 마커 등 상태 (기본 `${CLAUDE_PLUGIN_DATA}`, 폴백 `~/.claude/plugins/data/call-it-a-day-wonbywondev-plugins`)

## 의존성

- `jq` (hook의 prompt 파싱)
- vault 쓰기 자유(글로벌 CLAUDE.md): 라이브 캡처가 컨펌 없이 진행되려면 필요.

## 테스트

```bash
bash test/run_tests.sh
```

스크립트 로직(감지·마커·compass 최신성·게이트·hook)은 TDD로 커버. 마무리 요약·노트 작성은 스킬(모델) 절차라 실사용(📱)로 검증.
