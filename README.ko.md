# claude-plugins

[English](./README.md)

wonbywondev의 개인 [Claude Code](https://claude.ai/code) 플러그인 모음.

## 플러그인

### [preserve-session](./plugins/preserve-session)

프로젝트 디렉토리 이름 변경, 이동, 복사 시에도 Claude Code 세션 히스토리를 보존합니다.

각 프로젝트에는 경로와 독립적인 UUID가 `.claude/hash.txt`에 저장됩니다. 글로벌 레지스트리가 UUID → 현재 경로를 매핑하고, 디렉토리가 rename 또는 move되면 `/preserve-session:fix`가 내부 세션 폴더 이름을 바꾸고 레지스트리를 갱신하여 이전 세션에 다시 접근할 수 있게 합니다.

**커맨드:** `fix` · `inherit` · `doctor` · `uninstall`

**훅:** `SessionStart` — 첫 실행 시 `.claude/hash.txt` 자동 초기화

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
