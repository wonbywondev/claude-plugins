# claude-plugins

[한국어](./README.ko.md)

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

### [skill-curator](./plugins/skill-curator)

_(In development)_ Auto-classifies skills as global vs project-specific and recommends matching skills from a central repository when starting new projects.

---

## License

MIT © 2026 SEONGIL WON. See [LICENSE](./LICENSE).
