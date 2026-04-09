---
name: recommend
description: Scan project stack and recommend matching skills from central repository
---

# skill-curator:recommend

Scan the current project and recommend skills from the central skills repository.

## Instructions

1. Run the detection script to identify the project's tech stack:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh
   ```

2. If the script outputs recommendations, present them to the user as a table:
   - Skill name
   - Namespace (if any)
   - Recommended scope: global or project
   - Already linked? (check both `~/.claude/skills/` and `.claude/skills/`)

3. Ask the user which skills to link. For each selected skill, run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --link <skill-name> --scope <global|project>
   ```

4. For namespaced skills (e.g., `notion/knowledge-capture`), linking the namespace folder links all skills in that namespace at once.

5. After linking, show the updated status:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --status --scope all
   ```
