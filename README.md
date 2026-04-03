# claude-plugins

A collection of plugins for [Claude Code](https://claude.ai/code).

## Plugins

### [preserve-session](./preserve-session)

Preserves Claude Code session history across project directory renames, moves, and copies.

Each project gets a path-independent UUID (`hash.txt`). A global registry maps UUID → current path. When a directory is renamed or moved, running `/preserve-session:fix` restores access to all previous sessions.

**Commands:** `fix` · `inherit` · `doctor` · `scan` · `cleanup` · `uninstall`

**Install:**
```
claude plugin install preserve-session
```

---

*More plugins coming soon.*
