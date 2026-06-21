# skill-manager

Acquire and curate Agent Skills into a central repo — the right way. Fetch a repo or local path, curate which skills to take, dedup by **purpose-digest + LLM judgment**, audit and rename to the frontmatter name, record provenance, and **flat-symlink** into global or project scope.

No LEANN / vector DB. The dedup engine is a lexical prefilter (zero LLM tokens for the common case) plus a 1-2 line purpose-digest per skill (the body is read exactly once, at install). See `compass/context.md` for the full design and the rationale for dropping LEANN.

## Use

```
/skill-manager:add <repo-url|local-path> [--scope global|project:<path>]
/skill-manager:status [skill-name]
```

Or just say it: *"이 repo로 스킬 설치해줘"* / *"install skills from this repo"* — the companion skill triggers.

## Pipeline

`fetch → select → digest → dedup → audit → place → register → link`

- **fetch** — clone/copy, enumerate candidates (handles `SKILL.md`, `skills/<n>/`, flat, lowercase; excludes nested refs & dangling symlinks).
- **select** — recommend a subset; flag superseded (`*-v1`), already-installed, tool-overlap.
- **digest** — read each body once → 1-2 line purpose-digest (the dedup unit).
- **dedup** — lexical prefilter → top-K; empty = no dup (no LLM). Else judge digests; subagent reads bodies only when ambiguous. Trigger-keyword collisions → routing-note suggestion.
- **audit** — validate frontmatter; resolve invocation name (frontmatter `name`, normalized).
- **place** — copy into `$SKILLS_REPO/<invocation_name>` (rename); source-grouping `<group>/<name>`; carry LICENSE.
- **register** — `registry.json`: source, source_type, fork_commit, license, upstream_dir, **digest**, trigger_keywords, scope, link_mode.
- **link** — flat per-skill symlink into global (`$GLOBAL_SKILLS_DIR`) or `project:<path>/.claude/skills`. Group folders are never linked whole (Claude Code discovers one level only).

## Paths (env override)

```
SKILLS_REPO        ${SKILLS_REPO:-~/dev/agent/skills}        central repo
GLOBAL_SKILLS_DIR  ${GLOBAL_SKILLS_DIR:-~/.claude/skills}    global activation
SKILL_MANAGER_HOME ${SKILL_MANAGER_HOME:-~/.claude/skill-manager}  registry.json
```

## Layout

```
lib/      common.sh fetch.sh select.sh digest.sh dedup.sh audit.sh place.sh register.sh link.sh
commands/ add.md status.md
skills/skill-manager/SKILL.md
test/     run_tests.sh test_*.sh   (bash harness; 85 tests)
```

## Develop / test

```bash
bash test/run_tests.sh
```

Shell helpers are TDD'd (RED→GREEN→REFACTOR). LLM/subagent steps (digest text, dedup judgment) are exercised via the orchestration in `SKILL.md`; shell tests cover the deterministic surface (prefilter, enumeration, placement, registry, linking).

## Scope (v1 / later)

- **v1 (this):** Acquire core — the pipeline above.
- **v2:** update-track — 3-way merge from `fork_commit`, digest regen.
- **v3:** recommend (post-plan) · organize (regroup/re-symlink existing skills, stale-link repair) · distribute.
