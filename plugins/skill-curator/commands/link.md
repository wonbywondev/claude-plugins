---
name: link
description: Link a skill from the central repository to global or project scope
---

# skill-curator:link

Link skills from the central skills repository.

## Instructions

1. List available skills from the central repository:
   ```bash
   source ${CLAUDE_PLUGIN_ROOT}/hooks/common.sh && list_central_skills
   ```

2. Ask the user which skill(s) to link.

3. For each skill, classify it to recommend scope:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/classify.sh <skill-name>
   ```

4. Ask the user to confirm scope (global or project), then link:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --link <skill-name> --scope <global|project>
   ```

5. Show result:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --status --scope all
   ```
