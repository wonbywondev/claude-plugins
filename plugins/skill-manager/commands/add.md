---
description: Acquire & curate Agent Skills from a repo or local path into the central repo
argument-hint: <repo-url|local-path> [--scope global|project:<path>]
---

Acquire and curate skills from: **$ARGUMENTS**

Run the skill-manager pipeline. Load helpers first:

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
for f in "${CLAUDE_PLUGIN_ROOT}"/lib/*.sh; do [ "$(basename "$f")" = common.sh ] || source "$f"; done
```

Then, using the `skill-manager` skill's runbook:

1. **fetch** the source to a temp staged dir (`sm_fetch_clone`), enumerate candidates (`sm_fetch_candidates`).
2. **select**: if multiple, run `sm_select_filter` and present the recommended subset + exclusions (superseded / already-installed / tool-overlap). Get user confirmation.
3. For each confirmed skill: **digest** (read body once via `sm_digest_prompt`, write a 1-2 line purpose-digest) → **dedup** (`sm_prefilter` over registry digests; empty = no dup, no LLM; else judge digests, subagent for ambiguous; `sm_shared_keywords` for trigger collisions → routing note).
4. **audit** (`sm_audit_check`, `sm_audit_invocation`) → **place** (`sm_place`, rename to invocation name, carry LICENSE) → **register** (`sm_register_upsert` incl. digest) → **link** (`sm_link`, flat, scope from `--scope` or recommend).

Report: what was installed, skipped (with reason), any dedup/trigger warnings, and the scope of each symlink. Never link group folders whole; never auto-create a plugin for third-party skills.
