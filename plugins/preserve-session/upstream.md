---
plugin: preserve-session
plugin_ack: v2.1.119
plugin_applied: v2.1.119
updated_at: 2026-04-24
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
