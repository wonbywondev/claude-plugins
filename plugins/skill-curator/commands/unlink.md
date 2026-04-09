---
name: unlink
description: Remove a skill symlink from global or project scope
---

# skill-curator:unlink

Remove skill symlinks.

## Instructions

1. Show currently linked skills:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --status --scope all
   ```

2. Ask the user which skill(s) to unlink and from which scope (global/project).

3. For each selected skill:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --unlink <skill-name> --scope <global|project>
   ```

4. Show updated status:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --status --scope all
   ```
