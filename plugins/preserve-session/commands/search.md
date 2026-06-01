---
description: Search all past Claude Code sessions for a keyword and get ready-to-run resume commands
argument-hint: <keyword>
allowed-tools: Bash(bash:*)
---

Search every session transcript under `~/.claude/projects` for the user's keyword.
The keyword is everything in `$ARGUMENTS`.

If `$ARGUMENTS` is empty, ask the user what keyword to search for, then proceed.

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/search.sh" "$ARGUMENTS"
```

Show the output. Each matched session lists its current project path, a hit count,
the last activity date, a snippet, and a `resume:` command. Matching is
case-insensitive and covers user + assistant text (thinking is excluded).

Sessions show their **current** path via the registry even if the project was
renamed or moved since the conversation happened. Sessions marked
`(unregistered)` were not tracked by preserve-session (e.g. subagent transcripts
or projects created without the plugin active), so their resume path is unknown —
the `claude --resume <id>` hint is best-effort.

If the user then wants to open one, they can copy the `resume:` line, or tell you
which session and you can surface more of its content.
