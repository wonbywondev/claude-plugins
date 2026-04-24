# claude-plugins

[![English](https://img.shields.io/badge/lang-English-lightgrey)](./README.md)

wonbywondev의 개인 [Claude Code](https://claude.ai/code) 플러그인 모음.

## 플러그인

### [preserve-session](./plugins/preserve-session/README.ko.md)

프로젝트 폴더 이름을 바꾸거나 다른 곳으로 옮겨도 Claude Code 대화 기록이 사라지지 않게 해줍니다.

플러그인이 프로젝트마다 고유 번호를 붙여 기억하기 때문에, 폴더를 옮겨도 `/preserve-session:fix` 한 번 실행하면 이전 대화를 다시 볼 수 있습니다.

**명령어:** `fix` · `copy` · `move` · `cleanup` · `doctor` · `uninstall` &nbsp;·&nbsp; ~~`inherit`~~ _(v1.2.0부터 사용 중단 — `copy` 또는 `move` 사용)_

첫 실행 시 자동으로 프로젝트를 등록합니다. 별도 설정 불필요.

**설치:**

```
claude marketplace add https://github.com/wonbywondev/claude-plugins
claude plugin install preserve-session
```

자세한 내용, 데모, 워크플로우는 [plugins/preserve-session/README.ko.md](./plugins/preserve-session/README.ko.md)를 참조하세요.

### [skill-curator](./plugins/skill-curator)

_(개발 중)_ 스킬을 global / project-specific으로 자동 분류하고, 새 프로젝트 시작 시 중앙 저장소에서 어울리는 스킬을 추천합니다.

---

## 라이선스

MIT © 2026 SEONGIL WON. [LICENSE](./LICENSE) 참조.
