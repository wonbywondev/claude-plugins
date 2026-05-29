---
plugin: preserve-session
plugin_ack: v2.1.156
plugin_applied: v2.1.156
updated_at: 2026-05-29
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

## ✅ Applied

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
