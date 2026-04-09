---
name: status
description: Show current skill symlinks (global and project)
---

# skill-curator:status

Show the current state of skill symlinks.

## Instructions

1. Run the status check:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/hooks/link.sh --status --scope all
   ```

2. Present the output to the user. Highlight any broken symlinks.

3. If there are broken symlinks, suggest running `/skill-curator:unlink` to clean them up.
