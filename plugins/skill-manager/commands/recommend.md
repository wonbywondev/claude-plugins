---
description: Recommend owned skills that fit a project, and offer to activate them
argument-hint: [project path or one-line brief]
---

Recommend skills for: **$ARGUMENTS**

Load helpers:

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
for f in "${CLAUDE_PLUGIN_ROOT}"/lib/*.sh; do [ "$(basename "$f")" = common.sh ] || source "$f"; done
```

Then:

1. **Catalog** — `sm_catalog` → owned skills as `name⇥desc`. Cohesive bundles (gstack) appear as one entry; grab-bag groups (korean/, taste-skill/) appear per-leaf.
2. **Project need** — from `$ARGUMENTS` (brief) and/or the project dir: detect stack (package.json / Cargo.toml / requirements.txt / *.xcodeproj …) and read its `CLAUDE.md` / compass `plan.md` if present.
3. **Rank (no vectors)** — YOU match need ↔ catalog directly. The catalog is small (~100-200 short lines); read it whole and pick the top-N relevant, handling Korean↔English / synonyms natively. **Prioritize dormant skills** (present in `SKILLS_REPO` but not symlinked anywhere — the 100+ in `korean/`, `gstack/` etc.).
4. **Relations** — after picking top-N (NOT during matching; the ledger adds ~0 to "what fits", it answers "what goes *together*"): `sm_routing_lookup "$(sm_skills_repo)/ROUTING.md" <top-N names...>` → if paragraphs come back, present combos/boundaries alongside ("X를 켜면 Y가 짝 — 순서: …"). Empty output = no recorded relations = skip silently.
5. **Present** top-N (+ relation combos) with a one-line "why it fits". On confirm, **activate** each into the project (default scope):

   ```bash
   sm_link "$(sm_skill_dir <name>)" <name> "project:<project-path>"
   ```

   (flat symlink into `<project>/.claude/skills/`; use `global` only if the user wants it everywhere).
6. **Notes** — cohesive bundles (gstack) activate as a single umbrella entry (its sub-skills are not individually exposed). Never activate the whole repo blindly; recommend a focused set.
