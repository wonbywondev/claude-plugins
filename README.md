# claude-plugins

[![한국어](https://img.shields.io/badge/lang-%ED%95%9C%EA%B5%AD%EC%96%B4-lightgrey)](./README.ko.md)

Personal [Claude Code](https://claude.ai/code) plugins by wonbywondev.

## Plugins

### [preserve-session](./plugins/preserve-session)

Keeps your Claude Code conversations alive when you rename, move, or copy your project folder.

The plugin tags each project with a unique ID, so even after you move the folder, running `/preserve-session:fix` once brings your old conversations back.

**Commands:** `fix` · `copy` · `move` · `cleanup` · `doctor` · `uninstall` &nbsp;·&nbsp; ~~`inherit`~~ _(deprecated in v1.2.0 — use `copy` or `move`)_

Auto-registers your project on first run. No configuration needed.

**Install:**

```
claude marketplace add https://github.com/wonbywondev/claude-plugins
claude plugin install preserve-session
```

See [plugins/preserve-session/README.md](./plugins/preserve-session/README.md) for details, demo, and workflows.

### [skill-manager](./plugins/skill-manager)

Manage the lifecycle of Agent Skills in a central repo: acquire (fetch/curate/dedup-by-digest/audit/provenance/flat-symlink), recommend skills that fit a project, and organize/dedup what you own. Token-frugal — lexical prefilter + LLM, no vectors. Nudges you toward a **dormant** skill when you name it (skill-aware hook), and surfaces unused active skills via usage stats (token hygiene).

**Commands:** `add` · `recommend` · `status`

See [plugins/skill-manager/README.md](./plugins/skill-manager/README.md).

### [call-it-a-day](./plugins/call-it-a-day)

Bound a workday with a greeting and roll the day's dev work into an Obsidian knowledge base — live-capture as it happens + wrap-up summary (per-project daily log, atomic knowledge notes). Includes a **compass-sync Stop gate** that blocks turn-end re-sync when a project's design docs go stale after code changes.

See [plugins/call-it-a-day/README.md](./plugins/call-it-a-day/README.md).

---

## License

MIT © 2026 SEONGIL WON. See [LICENSE](./LICENSE).
