---
name: skill-manager
description: Use when the user wants to manage Agent Skills — install/add/acquire from a repo or path ("install skills from this repo", "이 repo로 스킬 설치해줘", "add this skill"), recommend skills that fit a project ("이 프로젝트에 맞는 스킬 추천", "what skills fit here"), or organize/dedup what they own ("스킬 관리", "스킬 정리"). Acquire: fetch candidates, curate a subset, dedup by purpose-digest, audit/rename, record provenance, flat-symlink to global/project. Recommend: catalog owned skills → match project need → activate. Token-frugal: lexical prefilter + LLM, no vectors; bodies read once at install.
---

# skill-manager

Acquire third-party Agent Skills into the central repo (`~/dev/agent/skills`) the right way: curated, deduped, provenance-tracked, flat-symlinked. Engine is **lexical prefilter + purpose-digest + LLM judgment** (no LEANN/vector DB). Mechanics live in the plugin compass; this is the runbook.

> Load helpers once: `source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"` then source the other `lib/*.sh`.
> Or just run `/skill-manager:add <repo|path>`.

## Pipeline

1. **fetch** — `sm_fetch_clone <repo|path> <staged>` then `sm_fetch_candidates <staged>` → TSV `rel⇥name⇥desc` (broken symlinks & nested refs excluded). No placement yet.
2. **select** — if multiple candidates, run `sm_select_filter "<tsv>" "$(sm_installed_tool_keywords)"` → per-candidate `keep|exclude(superseded|already-installed)|flag(tool-overlap)`. The tool-overlap keywords come from `lib/tools.map` filtered to *installed* CLIs (live discovery), so e.g. an `imagegen-*` candidate flags against an installed `pencil`. **Show the user the recommended subset and exclusions; let them confirm.** Single candidate → auto.
3. **digest** — for each confirmed skill, generate a **1-2 line purpose-digest** by reading the body ONCE: build the prompt with `sm_digest_prompt <skill.md> <name>`, then YOU write the digest text. This is the only time the body enters context.
4. **dedup (token-frugal)** —
   - Build the corpus with **`sm_dedup_corpus`** — *every owned skill* (catalog description) with registry purpose-digests overlaid where present. This compares the new skill against the **whole central repo (~400)**, not just the handful in the registry. One python pass.
   - `sm_prefilter "<new-digest>" "$(sm_dedup_corpus)" 8 0.08` → top-K candidates. **Empty → no duplicate, skip the LLM judge entirely.**
   - If candidates: compare the new digest against each candidate digest yourself (short text) → duplicate / similar / distinct. Only if digests are genuinely ambiguous, **spawn a subagent** to read the candidate + new bodies and return just a verdict (keeps main context clean).
   - Trigger collision: `sm_shared_keywords "<new-triggers>" "<existing-triggers>"`; if they overlap, warn and **propose a routing note** (CLAUDE.md / wiki), as with pencil ↔ design skills.
   - On duplicate/similar, ask: continue / cancel / replace.
5. **audit** — `sm_audit_check <skill.md>` (fix missing frontmatter); `sm_audit_invocation <skill.md> <upstream_dir>` → the **invocation name** (= place folder name; frontmatter `name` normalized).
6. **place** — `sm_place <src> <invocation_name> [group] [license_file]`. Folder name = invocation name (rename). Group only in the source repo (e.g. `taste-skill/<name>`); third-party → carry LICENSE.
7. **register** — `sm_register_upsert <name> source=… source_type=git|npm|local fork_commit=… license=… upstream_dir=… digest="…" trigger_keywords="…" scope=… link_mode=copy`.
8. **link** — `sm_link <placed_dir> <invocation_name> <scope>` (scope `global` or `project:<path>`). **Flat, per-skill** — never link a group folder whole. If scope unspecified, recommend: always-useful → global; situational/variant → project or leave unlinked (token cost: each active skill's description is resident every session).

## Recommend (project → owned skills)

When the user wants skills *for a project* ("이 프로젝트에 맞는 스킬 추천", "what skills fit here"), or via `/skill-manager:recommend [brief]`:
- `sm_catalog` → owned-skill catalog (`name⇥desc`; cohesive bundle = 1, grab-bag = per-leaf).
- Match the project need (brief + detected stack + its CLAUDE.md/plan) against the catalog **directly — no vectors** (catalog is small; read it whole, handle Korean↔English). Pick top-N, **prioritizing dormant skills** (in `SKILLS_REPO` but unlinked — e.g. `korean/`, `gstack/`).
- Offer to activate: `sm_link "$(sm_skill_dir <name>)" <name> "project:<path>"` (flat symlink into the project; `global` only if asked). Cohesive bundles activate as one umbrella entry.

## Defaults & guards

- Third-party skills are **vendored + symlinked**, not turned into plugins/marketplace entries (that is for your own work).
- Skip broken/dangling symlinks everywhere (they crash indexers).
- Don't eager-backfill digests for the ~400 existing skills; generate lazily when one becomes a prefilter candidate.

## Helpers

`source ${CLAUDE_PLUGIN_ROOT}/lib/common.sh` then `lib/{fetch,select,digest,dedup,audit,place,register,link,recommend,usage,skill_aware}.sh`. Paths via `SKILLS_REPO` / `GLOBAL_SKILLS_DIR` / `SKILL_MANAGER_HOME` (env override).

## Usage stats (sm_usage) — 토큰 위생
`sm_usage [projects_dir]` → transcript의 Skill 호출을 집계(`skill⇥count⇥last_used`, 호출순). `/skill-manager:status`가 함께 표시. **활성인데 호출 0 = 매 세션 description 토큰 상주** 후보를 드러냄. 단 ① dormant는 항상 0(비활성이라 무의미) ② 상황대기형(gpt-taste·variant)은 0이어도 유지. ⚠ **강등은 자동 X — 사용자가 "스킬 정리" 요청할 때만** 통계 근거로 함께 논의.
