# skill-manager

[English](./README.md)

중앙 저장소의 Agent Skill **생애주기**를 관리. **획득(Acquire)** — repo나 로컬 경로에서 가져와, 어떤 스킬을 취할지 큐레이션, **purpose-digest + LLM 판정**으로 중복제거, frontmatter name으로 audit·리네임, provenance 기록, 글로벌/프로젝트로 **flat-symlink**. **추천(Recommend)** — 프로젝트에 맞는 보유 스킬 제시. **조직(Organize)** — 보유 스킬 재그룹·재링크·중복제거.

LEANN/벡터 DB 없음. 중복제거 엔진은 어휘 프리필터(흔한 경우 LLM 토큰 0) + 스킬당 1~2줄 purpose-digest(본문은 설치 시 딱 한 번 읽음). 전체 설계·LEANN 폐기 근거는 `compass/context.md` 참조.

## 사용

```
/skill-manager:add <repo-url|local-path> [--scope global|project:<path>]
/skill-manager:recommend [brief]        # 이 프로젝트에 맞는 보유 스킬 → 활성화 제안
/skill-manager:status [skill-name]
```

또는 말로: *"이 repo로 스킬 설치해줘"* / *"install skills from this repo"* — 동반 스킬이 트리거됨.

## 파이프라인

`fetch → select → digest → dedup → audit → place → register → link`

- **fetch** — clone/copy 후 후보 열거(`SKILL.md`·`skills/<n>/`·flat·소문자 처리, 중첩 ref·dangling 심링크 제외).
- **select** — 부분집합 추천; superseded(`*-v1`)·이미설치·도구중복 플래그.
- **digest** — 각 본문 1회 읽어 1~2줄 purpose-digest(중복제거 단위).
- **dedup** — `sm_dedup_corpus`(보유 전 스킬의 카탈로그 desc + registry digest 덮어씌움)로 **레지스트리뿐 아니라 전체 중앙 repo**와 비교. 어휘 프리필터 → top-K; 비면 중복 아님(LLM 0). 후보 있으면 digest 비교, 애매할 때만 서브에이전트가 본문. 트리거 키워드 충돌 → 라우팅 노트 제안.
- **audit** — frontmatter 검증; invocation name 결정(frontmatter `name` 정규화).
- **place** — `$SKILLS_REPO/<invocation_name>`로 복사(리네임); 소스 그룹핑 `<group>/<name>`; LICENSE carry.
- **register** — `registry.json`: source·source_type·fork_commit·license·upstream_dir·**digest**·trigger_keywords·scope·link_mode.
- **link** — 글로벌(`$GLOBAL_SKILLS_DIR`) 또는 `project:<path>/.claude/skills`로 flat per-skill 심링크. 그룹 폴더 통째 링크 금지(Claude Code는 1레벨만 디스커버리).

## skill-aware (dormant 스킬 호명 시 안내)

UserPromptSubmit 훅 — 프롬프트가 **dormant(보유했으나 글로벌 미링크) 스킬을 호명 + 활용의도**("써/사용/활용/돌려…")일 때만 *"skill-manager로 활성화"* 안내를 주입. 활성 스킬은 네이티브로 발동하니 침묵, `pdf`·`notion` 같은 일반명사 스킬 false-positive는 활용의도 게이트로 회피.

## sm_usage (사용통계 — 토큰 위생)

전체 세션 transcript의 Skill 호출을 집계(`skill⇥count⇥last_used`, 호출순). `/skill-manager:status`가 함께 표시 → **활성인데 호출 0**(매 세션 description 토큰 상주)을 드러냄. ⚠ 강등은 자동 X — 사용자 "스킬 정리" 요청 시에만 통계 근거로 논의(dormant는 항상 0이라 무의미, 상황대기형 variant는 유지).

## 경로 (env override)

```
SKILLS_REPO        ${SKILLS_REPO:-~/dev/agent/skills}        중앙 저장소
GLOBAL_SKILLS_DIR  ${GLOBAL_SKILLS_DIR:-~/.claude/skills}    글로벌 활성화
SKILL_MANAGER_HOME ${SKILL_MANAGER_HOME:-${CLAUDE_PLUGIN_DATA:-~/.claude/plugins/data/skill-manager-wonbywondev-plugins}}  registry.json
```

## 구조

```
lib/      common fetch select digest dedup audit place register link recommend usage skill_aware  (.sh)
commands/ add.md recommend.md status.md
hooks/    skill-aware.sh hooks.json   # UserPromptSubmit: dormant 스킬 호명 시 활성화 안내
skills/skill-manager/SKILL.md
test/     run_tests.sh test_*.sh   (bash 하네스; 122 tests)
```

## 개발 / 테스트

```bash
bash test/run_tests.sh
```

셸 헬퍼는 TDD(RED→GREEN→REFACTOR). LLM/서브에이전트 단계(digest 텍스트·dedup 판정)는 `SKILL.md` 오케스트레이션으로 검증; 셸 테스트는 결정적 표면(프리필터·열거·배치·레지스트리·링크) 커버.

## 범위 (완료 / 후속)

- **획득**(완료) — 위 파이프라인.
- **추천**(완료) — 프로젝트 need → 보유 스킬 매칭 → 활성화 제안(`/skill-manager:recommend`).
- **후속:** update-track(`fork_commit`에서 3-way merge, digest 재생성) · organize(보유 스킬 재그룹·재링크, stale-link 복구) · distribute.
