---
description: List all registered projects and remove selected entries from the registry
allowed-tools: Bash(bash:*)
---

**Step 1** — Run the following and show the output to the user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/cleanup.sh"
```

**Step 2** — If the output says "nothing to clean up" or "registry is empty", inform the user and stop.

Otherwise, ask the user which entries to remove:

> 삭제할 항목 번호를 입력하세요 (예: `1 3`). `stale`을 입력하면 `✗ ← path not found`로 표시된 항목 전체를, `all`을 입력하면 모든 항목을 삭제합니다.

**Step 3** — Translate the user's selection into paths (do NOT run the command yet):

- **Numbers** (e.g. `1 3`): pick the paths at those positions from the displayed list
- **`stale`**: pick all paths where the status character was `✗` (i.e., lines containing `← path not found`)
- **`all`**: pick all paths from the displayed list

Then show the user exactly which paths will be removed and ask for confirmation:

> 다음 항목들을 registry에서 제거합니다:
> - `/path/one`
> - `/path/two`
>
> 계속하시겠습니까?

**Step 4** — After explicit confirmation, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/cleanup.sh" --remove "/path/one" "/path/two"
```

Show the result to the user. If the user declines, say "취소되었습니다. registry가 변경되지 않았습니다."

**Note:** This command only removes entries from the registry. It does not delete `hash.txt` files, project directories, or session data (`~/.claude/projects/`).
