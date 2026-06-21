# Phase 1 — common.sh (공유 헬퍼)

# --- path helpers: env override 존중 ---
assert_eq "sm_skills_repo honors SKILLS_REPO" "$MOCK_CENTRAL" "$(sm_skills_repo)"
assert_eq "sm_global_dir honors GLOBAL_SKILLS_DIR" "$MOCK_GLOBAL" "$(sm_global_dir)"
assert_eq "sm_home honors SKILL_MANAGER_HOME" "$SKILL_MANAGER_HOME" "$(sm_home)"

# --- path helpers: 기본값 (env unset 시) ---
assert_eq "sm_skills_repo default" "$HOME/dev/agent/skills" "$(unset SKILLS_REPO; sm_skills_repo)"
assert_eq "sm_global_dir default" "$HOME/.claude/skills" "$(unset GLOBAL_SKILLS_DIR; sm_global_dir)"
# sm_home: 우선순위 SKILL_MANAGER_HOME > CLAUDE_PLUGIN_DATA(런타임 표준) > plugins/data 폴백
assert_eq "sm_home honors CLAUDE_PLUGIN_DATA" "/tmp/sm-pd-test" "$(unset SKILL_MANAGER_HOME; CLAUDE_PLUGIN_DATA=/tmp/sm-pd-test sm_home)"
assert_eq "sm_home default → plugins/data 표준" "$HOME/.claude/plugins/data/skill-manager-wonbywondev-plugins" "$(unset SKILL_MANAGER_HOME CLAUDE_PLUGIN_DATA; sm_home)"

# --- 스킬 열거: flat + group leaf, 정렬 ---
sm_expected="code-python
gstack-qa
knowledge-capture
meeting-intelligence
node-configuration
pdf
systematic-debugging
test-driven-development"
assert_eq "sm_list_skills enumerates flat+group leaves" "$sm_expected" "$(sm_list_skills)"

# --- broken/dangling 심링크 제외 ---
mkdir -p "$MOCK_CENTRAL/broken-skill"
ln -s "/nonexistent/path/SKILL.md" "$MOCK_CENTRAL/broken-skill/SKILL.md"
sm_brk_out="$(sm_list_skills)"
if echo "$sm_brk_out" | grep -q "broken-skill"; then
  echo -e "${RED}FAIL${NC}: broken symlink skill excluded"; FAIL=$((FAIL+1))
else
  echo -e "${GREEN}PASS${NC}: broken symlink skill excluded"; PASS=$((PASS+1))
fi
rm -rf "$MOCK_CENTRAL/broken-skill"

# --- 플랫 스킬의 중첩 reference SKILL.md는 별도 스킬로 안 셈 ---
mkdir -p "$MOCK_CENTRAL/pdf/references"
touch "$MOCK_CENTRAL/pdf/references/SKILL.md"
sm_nest_out="$(sm_list_skills)"
if echo "$sm_nest_out" | grep -qx "references"; then
  echo -e "${RED}FAIL${NC}: nested reference SKILL.md not counted as skill"; FAIL=$((FAIL+1))
else
  echo -e "${GREEN}PASS${NC}: nested reference SKILL.md not counted as skill"; PASS=$((PASS+1))
fi
rm -rf "$MOCK_CENTRAL/pdf/references"
