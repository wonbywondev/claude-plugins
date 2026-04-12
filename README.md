# claude-plugins

[한국어](./README.ko.md)

Personal [Claude Code](https://claude.ai/code) plugins by wonbywondev.

## Plugins

### [preserve-session](./plugins/preserve-session)

Preserves Claude Code session history across project directory renames, moves, and copies.

Each project gets a path-independent UUID stored in `.claude/hash.txt`. A global registry maps UUID → current path. When a directory is renamed or moved, running `/preserve-session:fix` renames the internal sessions folder and updates the registry, restoring access to all previous sessions.

**Commands:** `fix` · `inherit` · `doctor` · `uninstall`

**Hook:** `SessionStart` — auto-initializes `.claude/hash.txt` on first run

**Install:**

```
claude marketplace add https://github.com/wonbywondev/claude-plugins
claude plugin install preserve-session
```

See [plugins/preserve-session/README.md](./plugins/preserve-session/README.md) for details, demo, and workflows.

### [skill-curator](./plugins/skill-curator)

_(In development)_ Auto-classifies skills as global vs project-specific and recommends matching skills from a central repository when starting new projects.

---

## License

MIT © 2026 SEONGIL WON. See [LICENSE](./LICENSE).
