# Phase 9 — link (flat 심링크)

LK_OLD="$GLOBAL_SKILLS_DIR"
export GLOBAL_SKILLS_DIR="$TMPDIR_ROOT/lk-global"; mkdir -p "$GLOBAL_SKILLS_DIR"
LK_PROJ="$TMPDIR_ROOT/lk-proj"

# skill 소스(SKILL.md 보유) + 그룹 폴더(SKILL.md 없음)
mkdir -p "$TMPDIR_ROOT/lk-src/myskill"; printf -- '---\nname: myskill\n---\n' > "$TMPDIR_ROOT/lk-src/myskill/SKILL.md"
mkdir -p "$TMPDIR_ROOT/lk-src/groupdir/sub"; printf 'x' > "$TMPDIR_ROOT/lk-src/groupdir/sub/SKILL.md"

# --- global flat 심링크 ---
lk="$(sm_link "$TMPDIR_ROOT/lk-src/myskill" myskill global)"
assert_eq "global link path" "$GLOBAL_SKILLS_DIR/myskill" "$lk"
assert_symlink "global link is symlink" "$GLOBAL_SKILLS_DIR/myskill"
assert_eq "link points to src" "$TMPDIR_ROOT/lk-src/myskill" "$(readlink "$GLOBAL_SKILLS_DIR/myskill")"

# --- 멱등(같은 타겟 재링크 → rc 0) ---
sm_link "$TMPDIR_ROOT/lk-src/myskill" myskill global >/dev/null 2>&1; lk_rc=$?
assert_eq "idempotent re-link rc=0" "0" "$lk_rc"

# --- project scope ---
lk2="$(sm_link "$TMPDIR_ROOT/lk-src/myskill" myskill "project:$LK_PROJ")"
assert_eq "project link path" "$LK_PROJ/.claude/skills/myskill" "$lk2"
assert_symlink "project link symlink" "$LK_PROJ/.claude/skills/myskill"

# --- 그룹 폴더 통째 심링크 거부(SKILL.md 없음) ---
if sm_link "$TMPDIR_ROOT/lk-src/groupdir" groupdir global >/dev/null 2>&1; then
  echo -e "${RED}FAIL${NC}: 그룹 통째 링크 거부"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 그룹 통째 링크 거부"; PASS=$((PASS+1)); fi

# --- 충돌: 다른 타겟의 동명 링크 존재 → 거부 ---
ln -s /somewhere/else "$GLOBAL_SKILLS_DIR/collide"
if sm_link "$TMPDIR_ROOT/lk-src/myskill" collide global >/dev/null 2>&1; then
  echo -e "${RED}FAIL${NC}: 충돌 거부"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 충돌 거부"; PASS=$((PASS+1)); fi

export GLOBAL_SKILLS_DIR="$LK_OLD"
