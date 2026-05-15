---
plugin: preserve-session
plugin_ack: v2.1.142
plugin_applied: v2.1.142
updated_at: 2026-05-15
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
