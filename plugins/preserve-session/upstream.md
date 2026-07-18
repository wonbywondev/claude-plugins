---
plugin: preserve-session
plugin_ack: v2.1.212
plugin_applied: v2.1.212
updated_at: 2026-07-18
---

<!-- Latest Claude Code release is fetched dynamically via Shields.io in README. -->
<!-- This file tracks the plugin's own ack/applied state only. -->


# Upstream impact log — preserve-session

Claude Code 릴리스가 이 플러그인에 미치는 영향 추적.

**Baseline 정책**: plugin v1.3.1 개발/테스트 환경이 Claude Code `v2.1.112` (2026-04-16).
이 이하 릴리스는 실사용으로 검증된 것으로 간주 (개별 검토 생략).
이후 릴리스(`v2.1.113` 이후)부터 본격 추적.

## 🟡 To-check

_비어 있음._

## 🔬 검증 완료 (v2.1.212 실측 — 재발 시 재검토)

sweep에서 impact:none으로 판정했던 두 엣지 조건을 **실제 라이브 테스트로 확정**(2026-07-18). 둘 다 현재 CLI에서 **비이슈**. 단 검증은 v2.1.212 한정이므로 재검토 트리거를 명시. 코드 가드는 추가하지 않음(실측상 불필요 + 추측 가드는 정상 파일 오탐).

### W1 — auto mode transcript-변조 차단 규칙 × copy/move (v2.1.205) → **비이슈 확정**
- **릴리스**: "Added an auto mode rule that blocks tampering with session transcript files."
- **실측 (3단 테스트, `--permission-mode auto`)**:
  - **Q-A**: bash 명령 문자열에 `~/.claude/projects/….jsonl`을 직접 넣고 append → **분류기가 하드 차단** ("권한 분류기가 이 동작을 차단"). 파일 불변. → 규칙은 **명령 문자열의 transcript 경로를 패턴 매칭**.
  - **Q-B decisive**: 실제 `move.sh`를 실제 호출 방식(`bash <plugin>/hooks/move.sh <src>`)으로 auto mode 실행 → **정상 실행, 세션 src→dst 이동 완료, 차단 없음**.
- **왜 안 막히나**: 우리 커맨드 문자열은 플러그인 스크립트 경로 + 일반 소스 경로만 노출하고 **transcript 경로(`~/.claude/projects`)를 포함하지 않음**. 실제 쓰기는 Python 내부(os.replace)라 문자열 기반 분류기가 가로채지 못함.
- **재검토 트리거**: CC가 이 규칙을 **파일시스템/샌드박스 레벨 가로채기**로 바꾸면(명령 문자열 무관하게 `~/.claude/projects` 쓰기 차단) copy/move가 auto mode에서 막힐 수 있음. 그때 커맨드 문서에 "auto mode에선 수동 승인 필요" 안내 추가.

### W2 — `/fork` 포인터-stub transcript × copy/move rewrite (v2.1.118 도입) → **비이슈 확정**
- **타임라인**: v2.1.118(2026-04-23) "`/fork`이 부모 대화 전체를 쓰던 것 → pointer를 쓰고 read 시 hydrate". v2.1.212(2026-07-17) `/fork`이 대화를 새 background 세션으로 **copy**. ※ v2.1.118은 과거 baseline sweep(113~170)이 놓친 것 — 이번에 소급 포착.
- **실측 (실제 fork 생성 + 파일 구조 분석)**: `claude -p --session-id` seed 세션 → `claude -p --resume <sid> --fork-session` 포크 → 결과 `.jsonl`:
  - **자기완결 full transcript** (25줄 = seed 15줄 + 새 턴, 59KB). seed 내용(SEED-ALPHA) 통째 포함.
  - 모든 `sessionId`가 **새 UUID**뿐, 부모 sid 참조 **없음**, pointer/hydrate/parentSession 필드 **없음**.
- **결론**: 디스크상 fork `.jsonl`은 **우리 copy.sh 산출물과 구조 동일**(전 sessionId rewrite된 self-contained transcript). copy/move에게 그냥 평범한 세션 → **가드 불필요, 깨질 리스크 없음**. v2.1.118의 "pointer" 최적화는 디스크 `.jsonl` 표면이 아닌 내부 표현이거나 v2.1.212 "copies"로 대체됨.
- **재검토 트리거**: 향후 CC가 fork를 **디스크상 pointer-stub `.jsonl`**(부모 참조, 소용량)로 저장하면 copy.sh의 sessionId rewrite가 hydrate를 깰 수 있음. 그때 "pointer 감지 시 skip+경고" 가드 TDD 추가. (참고: copy.sh는 모르는 라인 verbatim 보존이라 그 경우에도 데이터 손실은 없고 최악이 "hydrate 실패".)

## ✅ Applied

<details><summary>v2.1.172~212 (2026-06-10~07-17) — no-op apply (impact: none; W1/W2 watch 분리)</summary>

**Sweep 범위**: v2.1.170(직전 ack) 이후 34개 릴리스(172~212, 중간 yank 번호 171/180/182/184/188/189/192/194 등 제외). 34개 전체를 도메인 키워드(SessionStart 훅·transcript·resume·slug·path·cwd·registry·cleanup·plugin manifest·경로 인코딩)로 스크리닝 → 8개만 표면 접촉, 26개는 명백 무관(VSCode·subagent·background agent·remote control·MCP·/plugin UI·LSP·screen-reader 등).

**도메인 접촉 8건 판정**:
- **v2.1.181** — 30일 transcript cleanup 경합으로 idle 세션 히스토리 삭제하던 CC 자체 버그 픽스. 우리 존재 이유(세션 보존) 도메인의 **유리한 픽스**. slug/registry 무관.
- **v2.1.196** — (a) `/cd`로 옮긴 세션이 특수문자 경로에서 옛 디렉토리 resume 목록에 재등장하던 CC 내부 picker(cwd 필터) 픽스 — 우리 커맨드/slug 무관, v1.2.0 "picker=cwd 필터" 발견과 정합. (b) `claude plugin validate`가 source `"."` 스킵/첫 에러서 중단하던 것 픽스 — 우리 source는 `./plugins/...`라 무관, dev workflow 소폭 개선.
- **v2.1.199** — `SessionStart`/`Setup`/`SubagentStart` 훅이 **exit code 2**로 죽을 때 stderr 숨기던 것 → transcript 노출. 우리 훅은 `exit 0`만 써서 동작 변화 없음. **Forward-note**: 향후 치명적 초기화 실패를 사용자에게 알릴 새 수단(exit 2 + stderr)이 생김.
- **v2.1.204** — headless 세션 SessionStart 훅 이벤트 미스트리밍 → remote worker idle-reap 픽스. **유리**(우리 훅 신뢰성).
- **v2.1.205** — auto mode transcript-변조 차단 규칙 → **W1, 라이브 테스트로 비이슈 확정**(우리 커맨드 문자열이 transcript 경로 미노출 → 분류기 통과, 실제 move.sh auto mode 실행 성공). 검증 상세는 위 🔬 섹션.
- **v2.1.207** — plugin hook shell-form `${user_config.*}` 거부(injection 픽스). 우리는 `${CLAUDE_PLUGIN_ROOT}`(빌트인)만 쓰고 pluginConfigs 미선언 → **v2.1.212에서 `claude plugin validate` 통과로 무영향 실증**.
- **v2.1.208 / v2.1.212** — transcript 크기 축소(file-history backup 프루닝) / assistant 메시지에 reasoning-effort 필드 신규. 둘 다 additive·백업층 변경 — search.sh/copy.sh/move.sh는 필드 선택적 파싱이라 무영향.
- **fork 계열(v2.1.181/187/198/203/208/212)** — `/fork`은 같은 프로젝트 내 대화 분기(경로-복원인 우리와 직교, 상호 대체 아님). 포인터-stub 저장 리스크 → **W2, 실제 fork 생성해 비이슈 확정**(디스크 `.jsonl`은 self-contained full transcript, copy.sh 산출물과 동구조). 검증 상세는 위 🔬 섹션.

**실증**:
- `claude plugin validate .` → v2.1.212에서 `✔ Validation passed` (경고 1건은 v2.1.145부터의 CLAUDE.md 권고, 무해).
- 현재 CLI `2.1.212`. 이 세션이 최신 라인에서 정상 시작 — SessionStart 훅 발동, hash.txt → registry 매핑 동작.
- 사용자 세션 전수 스캔: fork/pointer 마커 0건 (W2 비발현 확인).

**결론**: 코드 변경 0건. ack/applied → v2.1.212 전진. 미발현 엣지 2건은 Watch 섹션(W1/W2)에 재현 절차와 함께 박제.

</details>

<details><summary>v2.1.157~170 (2026-05-29~06-09) — no-op apply (impact: none)</summary>

**Sources**: [157](https://github.com/anthropics/claude-code/releases/tag/v2.1.157) · [158](https://github.com/anthropics/claude-code/releases/tag/v2.1.158) · [159](https://github.com/anthropics/claude-code/releases/tag/v2.1.159) · [160](https://github.com/anthropics/claude-code/releases/tag/v2.1.160) · [161](https://github.com/anthropics/claude-code/releases/tag/v2.1.161) · [162](https://github.com/anthropics/claude-code/releases/tag/v2.1.162) · [163](https://github.com/anthropics/claude-code/releases/tag/v2.1.163) · [165](https://github.com/anthropics/claude-code/releases/tag/v2.1.165) · [166](https://github.com/anthropics/claude-code/releases/tag/v2.1.166) · [167](https://github.com/anthropics/claude-code/releases/tag/v2.1.167) · [168](https://github.com/anthropics/claude-code/releases/tag/v2.1.168) · [169](https://github.com/anthropics/claude-code/releases/tag/v2.1.169) · [170](https://github.com/anthropics/claude-code/releases/tag/v2.1.170)
(v2.1.164는 release not found — yank/skip 추정, N/A)

**핵심 검토 (SessionStart-only + 7개 커맨드 플러그인 관점)**:

- **v2.1.161 — "Windows hooks that invoke bash explicitly (`/usr/bin/bash script.sh`) failing with command not found" 픽스**: 우리 SessionStart 훅이 정확히 `bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh` 형식(`hooks.json`) → **우리에게 유리한 안정화 픽스** (Windows 사용자). 코드 변경 불필요, 오히려 신뢰성 향상.

- **v2.1.163 — 훅 관련 3건 전부 무관**: (1) Stop·SubagentStop 훅의 `hookSpecificOutput.additionalContext` → 우리는 SessionStart 단독. (2) `if: "Bash(...)"` 훅 조건이 `$()`/`$VAR` 포함 커맨드마다 오발화하던 픽스 → 우리 `hooks.json`은 `if:` 조건 없음. (3) stdio MCP에 `--resume` 시 `CLAUDE_CODE_SESSION_ID` 전달 → MCP 미사용.

- **v2.1.170 — transcript 저장 픽스 (인접 도메인, 우리에게 유리)**: "VS Code integrated terminal 또는 Claude Code 환경변수를 상속한 셸에서 launch 시 세션 transcript가 저장 안 되고 `--resume`에 안 뜨던 버그" 픽스. 이건 본체의 transcript `.jsonl` 저장 로직 픽스이지 slug/registry 산출 변경이 아님. preserve-session은 그 위에서 세션 *폴더*를 옮기는 도구라, transcript가 정상 저장되면 preserve 대상이 온전해져 **유리한 픽스**. 트리거("CC env 상속 셸에서 launch")는 새 `claude` 세션 실행 경로 — 우리 훅(`bash session-start.sh`)·커맨드(Bash 툴 서브프로세스)는 세션 spawn이 아니라 무관. 우리 README 경고는 VS Code *확장(extension)* 대상이고 이 픽스는 *통합 터미널*(CLI claude) 대상이라 별개 표면 — README 변경 불필요. (첫 항목 "Claude Fable 5" 신규 모델은 플러그인 무관.)

- **v2.1.169 — `/cd` 신규 (세션 중 작업 디렉토리 이동)**: 우리 도메인(폴더 rename/move)과 인접하나, `/cd`는 prompt cache 안 깨고 cwd만 변경하는 명령이지 transcript slug 폴더를 옮기는 게 아님 → slug/registry 산출 무관, 코드 영향 없음. **Forward-note**: 사용자가 `/cd`로 다른 프로젝트 경로로 이동 시 그 경로가 미등록이면 SessionStart 훅이 이미 새 세션에서 등록을 처리하므로 별도 대응 불필요. 동작 변경 발생 시 재검토.

- **v2.1.169 — `--safe-mode` (`CLAUDE_CODE_SAFE_MODE`)**: 모든 customization(CLAUDE.md/plugins/skills/hooks/MCP) 비활성 troubleshooting 모드. 설계상 의도된 동작 — safe mode에선 우리 훅도 안 도는 게 정상. **Forward-note**: doctor 안내문에 "세션이 안 잡히면 `--safe-mode`로 켠 건 아닌지 확인" 추가 검토 가능. 코드 변경 불필요.

- **v2.1.160/162/166 — 권한·파일쓰기 보안 강화 다수**: shell startup file(`.zshenv` 등) 쓰기 prompt, `acceptEdits` build-tool config prompt, Windows 백슬래시 permission rule 매칭, glob deny rule 등 — 전부 Edit/Write 툴 + permission 시스템. 플러그인 manifest로 로드되는 훅은 권한 시스템 우회하므로 무관. 우리 커맨드는 Bash 툴 경유 셸 실행이지만 startup file/build config를 쓰지 않음.

- **v2.1.157 — 대형 릴리스**: "Plugins in `.claude/skills` auto-load", `claude plugin init`, agents/worktree/UI 픽스 다수 — 우리 커맨드/훅/slug 경로 무관. 워크플로우 트리거 키워드 설정도 무관.

- **v2.1.158/159/165/167/168 — 무관**: Bedrock/Vertex auto mode, internal-only, "bug fixes and reliability improvements"(상세 없음).

**실증**: 이 세션이 최신 릴리스 라인에서 정상 시작 — SessionStart 훅 정상 발동, `hash.txt` → `~/.claude/project-registry.json` 매핑 등록 동작 확인.

**결론**: 코드 변경 불필요. ack/applied → v2.1.169 전진.

**참고**: 릴리스 인덱스(`.github/state/claude-code-releases.json`)는 CI(`upstream-watch.yml`) 정상 동작 중 — `last_updated: 2026-06-09`, top tag v2.1.169까지 최신. (작업 시작 시 로컬 복사본이 origin보다 뒤처져 v2.1.156으로 보였을 뿐. rebase 후 최신 확인.) 이번 sweep의 릴리스 노트 정독은 `gh api` 직접 조회로 수행.

</details>

<details><summary>v2.1.147~156 (2026-05-21~29) — no-op apply (impact: none)</summary>

**Sources**: [147](https://github.com/anthropics/claude-code/releases/tag/v2.1.147) · [148](https://github.com/anthropics/claude-code/releases/tag/v2.1.148) · [149](https://github.com/anthropics/claude-code/releases/tag/v2.1.149) · [150](https://github.com/anthropics/claude-code/releases/tag/v2.1.150) · [152](https://github.com/anthropics/claude-code/releases/tag/v2.1.152) · [153](https://github.com/anthropics/claude-code/releases/tag/v2.1.153) · [154](https://github.com/anthropics/claude-code/releases/tag/v2.1.154) · [156](https://github.com/anthropics/claude-code/releases/tag/v2.1.156)
(v2.1.151, v2.1.155는 release not found — yank/skip 추정, N/A)

**핵심 검토 (SessionStart-only 플러그인 관점)**:

- **v2.1.152 — SessionStart 훅 신규 기능 3건** (전부 opt-in, 우리 미사용 → 무관):
  - `SessionStart` 훅이 `hookSpecificOutput.sessionTitle`로 세션 타이틀 지정 가능 → 우리 훅은 성공 시 stdout 출력 0건(`exit 0`)이라 타이틀 미설정. (v2.1.144 "title이 monitor output에서 생성되던 버그" 픽스와 동일 맥락, 영향 없음 재확인.)
  - `SessionStart` 훅이 `reloadSkills: true` 반환 가능 → 우리는 skills 없음.
  - `MessageDisplay` 신규 훅 이벤트 → 미사용.
  - "git branch 추적 플러그인이 registry 재빌드 후 업데이트 못 받던 버그" 픽스 → preserve-session은 git-source라 **우리에게 유리한 픽스** (업데이트 정상화).

- **v2.1.147 — `/simplify` → `/code-review` 리네임 + cleanup 동작 제거**: 우리 커맨드(`cleanup`/`copy`/`doctor`/`fix`/`inherit`/`move`/`uninstall`)와 이름 충돌 없음. "shell snapshot이 `_`로 시작하는 함수 누락 픽스" → `common.sh` 함수(`find_python`/`path_to_slug`/`uuidgen_cross`/`nfc_normalize`/`registry_write`/`check_slug_collision`) 어느 것도 `_`로 시작 안 함, 무관. "plugin component count 중복 집계 픽스(manifest 경로가 default 디렉토리와 겹칠 때)" → 우리 `plugin.json`은 경로 키 미선언, 무관.

- **v2.1.148 — Bash 툴 exit 127 regression 픽스**: Agent의 Bash *툴* 버그이지 플러그인 훅 실행 경로 아님. 이 세션이 2.1.156에서 정상 시작된 것으로 훅 실행 정상 실증.

- **v2.1.149 — PowerShell 권한 우회 + `find` vnode 고갈 픽스**: PowerShell은 Windows 전용, `find`는 Bash 툴 — 둘 다 우리 SessionStart 훅 무관.

- **v2.1.150 — Internal only** / **v2.1.156 — Opus 4.8 thinking block API 에러 픽스**: 무관.

- **v2.1.153 — `--strict-mcp-config`/subagent MCP, npm update 채널, transcript 경로 resume 메모리 픽스 등**: 우리 MCP/subagent 미사용, slug/registry 로직 무관. "transcript file path로 resume 시 메모리 과다" 픽스는 Claude Code 내부 resume 처리 — 우리 path→slug 산출과 별개.

- **v2.1.154 — Opus 4.8, dynamic workflows, lean system prompt default**: 모델/기능 추가, 훅 무관. "`rm -rf $HOME` trailing slash 미차단 픽스"는 Bash 툴 dangerous-path 탐지 — `uninstall.sh`는 훅이 아닌 사용자 명시 실행 커맨드라 무관. "Plugins `defaultEnabled: false` 선언 가능" → opt-in, 우리 미선언.

**실증 (2.1.156)**:
- `claude plugin validate` → `✔ Validation passed` (경고 1건: plugin root `CLAUDE.md` project context 미로드 — 개발용 로컬 파일, v2.1.145부터 뜨는 권고, 동작 충돌 아님).
- SessionStart 훅 정상 작동: `hash.txt` → `~/.claude/project-registry.json` 매핑 정확 등록 확인 (`a756f2a8...` → 현재 경로).

**결론**: 코드 변경 불필요.

</details>

<details><summary>v2.1.146 (2026-05-21) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.146
**Impact**: none — built-in `/simplify` → `/code-review` 리네임은 우리 커맨드(`cleanup`/`copy`/`doctor`/`fix`/`inherit`/`move`/`uninstall`)와 이름 충돌 없음. Auto mode의 AskUserQuestion 처리, `CLAUDE_CODE_SUBAGENT_MODEL` 전파 픽스, Windows PowerShell/MCP pagination/터미널 렌더/auto-updater 픽스 등 모두 SessionStart-only 플러그인 scope 밖. **실증**: 이 릴리스(2.1.146)에서 SessionStart 훅 정상 시작 확인.

</details>

<details><summary>v2.1.145 (2026-05-19) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.145
**Impact**: none — Stop/SubagentStop 훅 입력에 `background_tasks`/`session_crons` 필드 추가 — 우리는 SessionStart 단독이라 무관. "bare env 변수 할당 권한 우회 픽스"는 Bash *툴* 권한 시스템 픽스 — 플러그인 훅은 Claude Code가 직접 실행하며 권한 시스템을 거치지 않음, 무관. `claude plugin validate`의 `skills:` 파일/디렉토리 검증 강화 — 우리 `plugin.json`은 `skills` 키 자체를 선언 안 함(default 디렉토리 탐색). **확인됨**: `claude plugin validate` 결과 `✔ Validation passed` — 단 plugin root `CLAUDE.md`가 project context로 로드 안 된다는 권고 경고 1건. 이는 개발용 로컬 파일(페르소나·compass 지침)로 의도된 상태이며 동작 충돌 아님.

</details>

<details><summary>v2.1.144 (2026-05-19) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.144
**Impact**: none — "session title이 plugin monitor output에서 생성되던 버그 픽스" — preserve-session은 monitor 미사용 + `common.sh`의 모든 출력이 stderr(`>&2`)이고 SessionStart 훅은 성공 시 조용히 `exit 0`, stdout 출력 0건이라 무관. "build가 skill 디렉토리 안에서 돌 때 fd 고갈 픽스" — 우리는 skills 없음. `/resume` background sessions, `/model` per-session, plugin 캐시 hint, MCP/터미널 픽스 다수 모두 외부.

</details>

<details><summary>v2.1.143 (2026-05-15) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.143
**Impact**: none — "stop 훅이 반복 차단 시 8회 후 종료(`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`)" — 우리는 Stop 훅 안 쓰고 SessionStart 단독이라 무관. "plugin dependency enforcement (`claude plugin disable/enable` 의존성 체인)" — preserve-session은 의존성 0이라 무관. `--agent <name>` plugin-contributed agent 매칭 픽스 — 우리는 agents 없음. `worktree.bgIsolation`, PowerShell, background session 다수 픽스 모두 외부.

</details>

<details><summary>v2.1.142 (2026-05-14) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.142
**Impact**: none — Fast mode가 Opus 4.7 default로 변경 (CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1 로 옛 모드 유지 가능). 플러그인 root-level `SKILL.md` 자동 인식 (우리는 SKILL.md 없음). `/plugin` browse pane 0 installs 표시 픽스, plugin advisory 픽스 등 모두 우리 무관. SessionStart/Setup/SubagentStart 훅에 prompt/agent type 사용 시 명확한 에러 메시지 추가 — 우리는 SessionStart에 정확히 `type: "command"` 사용해서 무관.

</details>

<details><summary>v2.1.141 (2026-05-13) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.141
**Impact**: none — `terminalSequence` 신규 hook output 필드 (우리 미사용, 향후 notification에 활용 가능). `CLAUDE_CODE_PLUGIN_PREFER_HTTPS`/`ANTHROPIC_WORKSPACE_ID` env vars 추가. `EnterWorktree` 후 hooks transcript_path 누락 픽스 (우리 SessionStart 훅은 transcript_path 안 씀). MCP/Remote Control 다수 픽스, UI/UX 픽스 다수 — 모두 외부.

</details>

<details><summary>v2.1.140 (2026-05-12) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.140
**Impact**: none — Agent tool subagent_type case/separator-insensitive 매칭, `/goal` disableAllHooks 시 hang 픽스, symlinked settings.json regression 픽스 등 외부. **확인됨**: 플러그인 default component folder 가리는 키 경고 신규 — 우리 `plugin.json`은 `commands`/`hooks`/`skills` 어느 키도 선언 안 함 (모두 default 디렉토리 자동 탐색). 경고 안 뜸.

</details>

<details><summary>v2.1.139 (2026-05-11) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.139
**Impact**: none — 대형 release. `claude agents` view (Research Preview), `/goal` 신규, `claude plugin details`, transcript view navigation 등 신기능. 훅 관련 변경 3건: (1) `args: string[]` exec form 신규 (옵션, 우리는 standard `command` string 사용), (2) PostToolUse용 `continueOnBlock` config (우리는 PostToolUse 안 씀), (3) MCP stdio에 `CLAUDE_PROJECT_DIR` env 추가 (우리 MCP 없음). **확인됨**: "hooks now run without terminal access" — 우리 훅은 직접 TTY 미사용, stdout/stderr만 사용 (Claude Code가 캡처). 무관. 나머지 다수 픽스 모두 우리 scope 밖.

</details>

<details><summary>v2.1.138 (2026-05-09) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.138
**Impact**: none — release note 한 줄("Internal fixes"). 외부 사용자에게 영향 없는 내부 안정화로 추정.

</details>

<details><summary>v2.1.137 (2026-05-09) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.137
**Impact**: none — VS Code 익스텐션 Windows 활성화 픽스. 우리 플러그인 무관.

</details>

<details><summary>v2.1.136 (2026-05-08) — no-op apply (impact: none, 검증 1건)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.136
**Impact**: none — 가장 의심스러운 항목 "Fixed --resume / --continue not finding sessions when the project path contains underscores"가 슬러그 알고리즘 변경인지 검증. 사용자 머신의 슬러그 폴더 forensic 결과: Claude Code 본체와 preserve-session `path_to_slug` 둘 다 `_`→`-` 변환 일관 적용 중. 즉 v2.1.136 fix는 검색(lookup) 로직 픽스일 뿐 인코딩 자체는 미변경. 우리 슬러그 산출과 Claude Code 슬러그 폴더 이름 일치 확인 (예: `-Users-won-dev-00-projects-claude-plugins-plugins-preserve-session`). 나머지 항목(MCP refresh token race, plan mode Edit allow rule, plugin Stop/UserPromptSubmit hook 캐시 클린업 등) 모두 우리 SessionStart-only 플러그인 scope 밖.

**참고**: 사용자 머신에 `-Users-won-dev-00_projects-tattoo-ar` (underscore preserved) 슬러그가 1건 있는데, 이는 별개 툴이 만든 것으로 추정 — psh4607이 issue #40946 5/05 코멘트에서 언급한 "encoding split across the ecosystem" 케이스로 정합. preserve-session 동작 변경과 무관.

</details>

<details><summary>v2.1.133 (2026-05-07) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.133
**Impact**: none — hooks가 `effort.level` JSON 입력 + `$CLAUDE_EFFORT` env로 effort 정보 받게 됨. 우리 SessionStart 훅은 이 정보 안 쓰지만 **장기 활용 가능** (예: high effort 시 verbose registry health check). 코드 변경 불필요. worktree.baseRef 설정, sandbox.bwrapPath 등 모두 외부.

</details>

<details><summary>v2.1.132 (2026-05-06) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.132
**Impact**: none — `CLAUDE_CODE_SESSION_ID` 가 Bash 툴 subprocess env에 추가됐는데 우리 훅은 Bash 툴 안 쓰고 직접 shell out (자체 env). vim operators NFD 손상 픽스는 입력 vim mode 처리 픽스로 우리 NFC slug 정규화와 무관 (도메인 다름 — 입력 텍스트 편집 vs 경로 인코딩). Indic conjunct cursor 핸들링도 입력 UI 픽스. 나머지 다수 픽스 모두 외부.

</details>

<details><summary>v2.1.131 (2026-05-06) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.131
**Impact**: none — VS Code 익스텐션 Windows 활성화 픽스 + Mantle endpoint auth 픽스. 우리 무관.

</details>

<details><summary>v2.1.129 (2026-05-06) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.129
**Impact**: none — 플러그인 manifest의 `themes`/`monitors` 필드가 `experimental:{}` 아래로 권고됨. preserve-session은 둘 다 안 씀. `Bash(mkdir *)`/`Bash(touch *)` allow rule 픽스, gateway model discovery opt-in, Ctrl+R history picker 동작 변경, OAuth refresh race 픽스 등 모두 외부. 1-hour prompt cache TTL fix, `/context` rendered ASCII 토큰 낭비 픽스, 다수 UI/UX fix.

</details>

<details><summary>v2.1.128 (2026-05-04) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.128
**Impact**: none — MCP `workspace` 예약 이름, EnterWorktree 본 동작 픽스, `--plugin-dir` zip archive 지원, `/plugin update` npm-source 픽스 등 모두 플러그인 scope 밖. 우리는 git-source 플러그인이라 npm 관련 변경 무관. installed_plugins.json stale 엔트리 PATH 오염 픽스도 사용자 측 hygiene이라 우리 동작에 영향 없음.

</details>

<details><summary>v2.1.126 (2026-05-01) — no-op apply (impact: none, 운영 노트 1건)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.126
**Impact**: none — `claude project purge [path]` 신규 명령이 transcripts/tasks/file history/config entry를 삭제하는데, preserve-session의 `~/.claude/project-registry.json` 엔트리와 `<project>/.claude/hash.txt`는 Claude Code 데이터가 아니라서 purge 대상 아님. 결과적으로 stale 레지스트리 엔트리가 남을 수 있는데, 이건 `/preserve-session:cleanup` + `doctor`가 이미 처리하는 케이스와 동일. Windows CJK 렌더 픽스는 표시 개선만, slug 알고리즘 무관. `--dangerously-skip-permissions` 보호 경로 완화도 사용자 모드, 플러그인 동작 변경 없음.

**운영 노트**: 향후 README/cleanup 문서에 "claude project purge 후 stale 레지스트리는 /preserve-session:cleanup으로" 안내 추가 검토 가능. 코드 변경 불필요.

</details>

<details><summary>v2.1.123 (2026-04-29) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.123
**Impact**: none — OAuth 401 retry 루프 픽스 한 줄. 플러그인 무관.

</details>

<details><summary>v2.1.122 (2026-04-28) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.122
**Impact**: none — `/branch` 픽스, Vertex/Bedrock 픽스, ToolSearch 픽스 등 모두 플러그인 scope 밖. settings.json malformed-hooks 격리 픽스는 사용자가 settings.json에 직접 작성한 훅에만 적용 — 우리 훅은 플러그인 manifest로 로드되므로 무관.

</details>

<details><summary>v2.1.121 (2026-04-28) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.121
**Impact**: none — PostToolUse 훅에 `updatedToolOutput` 출력 추가는 플러그인이 SessionStart만 사용해서 무관. `claude plugin prune` 신규 (의존성 0이라 무관). `--resume` 관련 픽스 다수는 Claude Code 내부 처리, 우리 슬러그/레지스트리 미변경. "Bash tool becoming permanently unusable when the directory ... is deleted or moved mid-session" 픽스는 우리 도메인(폴더 rename)과 인접해 보이지만 Bash tool UX 픽스이지 session file 처리 변경 아님.

</details>

<details><summary>v2.1.119 (2026-04-23) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.119
**Impact**: none — `PostToolUse`/`PostToolUseFailure` 훅 입력에 `duration_ms` 추가는 이 플러그인이 해당 이벤트를 안 씀(SessionStart 단독)이라 무관. `/config` 값이 `~/.claude/settings.json`에 persist + precedence chain 참여하지만, 플러그인 훅은 manifest로 로드되므로 무관. 네이티브 빌드 Glob/Grep-when-Bash-denied 픽스도 플러그인 훅이 내부 도구를 안 써서 무관. MCP 서버/worktree agent/PowerShell auto-approve 등 모두 플러그인 scope 밖.

</details>

<details><summary>v2.1.118 (2026-04-23) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.118
**Impact**: none — 훅 관련 변경 3건 모두 무영향: (1) `type: "mcp_tool"` 신규 훅 타입은 이 플러그인이 `type: "command"`만 써서 무관, (2) agent-type 훅 이벤트 fix는 agent 훅 안 써서 무관, (3) `prompt` 훅 재발화 fix는 UserPromptSubmit 훅 안 써서 무관. `claude plugin tag` 신규 CLI는 git tag 기반 릴리스 도구로 옵션 사용. 테마/vim visual/MCP OAuth 등 모두 플러그인 scope 밖.

</details>

<details><summary>v2.1.117 (2026-04-22) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.117
**Impact**: none — `cleanupPeriodDays` 스윕 범위가 `~/.claude/tasks/`, `~/.claude/shell-snapshots/`, `~/.claude/backups/`로 확장됐지만 `~/.claude/projects/`는 여전히 기존 정책대로. README의 "Claude Code가 30일 지난 세션을 자동 삭제" 문구 유효. 네이티브 빌드 Glob/Grep→bfs/ugrep 치환은 플러그인 훅이 내부 도구 미사용이라 투명. 플러그인 install/dep 자동 해결/blockedMarketplaces 관련 변경은 의존성 0인 이 플러그인에 무관.

</details>

<details><summary>v2.1.116 (2026-04-20) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.116
**Impact**: none — sandbox rm safety check (새로 추가) hermetic uninstall 테스트로 무영향 확인. 나머지(`/resume` 속도, MCP startup, 터미널 UI 픽스 등) 모두 플러그인 scope 밖.
**Verified**: hermetic `bash uninstall.sh --confirm` in v2.1.116 — registry + hash.txt 정상 삭제, 그 어떤 prompt/지연 없음.

</details>

<details><summary>v2.1.114 (2026-04-18) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.114
**Impact**: none — agent-teams 권한 dialog 크래시 픽스뿐, 플러그인 실행 경로 무관.

> Fixed a crash in the permission dialog when an agent teams teammate requested tool permission

</details>

<details><summary>v2.1.113 (2026-04-17) — no-op apply (impact: none)</summary>

**Source**: https://github.com/anthropics/claude-code/releases/tag/v2.1.113
**Impact**: none — `plugin install` 의존성 처리 변경은 dependencies 필드 쓰는 플러그인만 영향 (preserve-session 무관). Native binary 전환은 투명. session-recap/compaction 관련 픽스는 UI/대화 흐름이라 plugin 훅과 무관.

> - Changed the CLI to spawn a native Claude Code binary (via a per-platform optional dependency)
> - Fixed session recap auto-firing while composing unsent text in the prompt
> - Fixed compacting a resumed long-context session failing with "Extra usage is required for long context requests"
> - Fixed `plugin install` succeeding when a dependency version conflicts with an already-installed plugin — now reports `range-conflict`
> - Fixed Remote Control sessions not streaming/archiving
> - (그 외 다수 fix, 전체 본문은 중앙 repo 참조)

</details>

<details><summary>v2.1.112 이하 (baseline anchor)</summary>

plugin v1.3.1 개발 & 실사용 테스트 환경. 각 릴리스별 개별 검토 생략 (pre-baseline 일괄 ack).
전체 목록은 중앙 repo `upstream-updates/` 참조.

</details>
