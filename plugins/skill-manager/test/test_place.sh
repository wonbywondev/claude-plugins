# Phase 7 — place (배치 + 리네임)

PLACE_REPO="$TMPDIR_ROOT/place-repo"; mkdir -p "$PLACE_REPO"
PL_OLD="$SKILLS_REPO"; export SKILLS_REPO="$PLACE_REPO"

# 업스트림 스킬(지저분한 폴더명 + .git + ref) + LICENSE
PL_SRC="$TMPDIR_ROOT/place-src/gpt-tasteskill"
mkdir -p "$PL_SRC/.git" "$PL_SRC/refs"
printf -- '---\nname: gpt-taste\ndescription: d.\n---\nbody\n' > "$PL_SRC/SKILL.md"
printf 'ref\n' > "$PL_SRC/refs/SKILL.md"
PL_LIC="$TMPDIR_ROOT/place-src/LICENSE"; printf 'MIT...\n' > "$PL_LIC"

# --- 그룹 배치 + 리네임 ---
pl_dest="$(sm_place "$PL_SRC" gpt-taste taste-skill "$PL_LIC")"
assert_eq "place dest path (group/rename)" "$PLACE_REPO/taste-skill/gpt-taste" "$pl_dest"
assert_file_exists "placed SKILL.md (renamed folder)" "$PLACE_REPO/taste-skill/gpt-taste/SKILL.md"
assert_file_exists "ref preserved" "$PLACE_REPO/taste-skill/gpt-taste/refs/SKILL.md"
assert_file_exists "LICENSE 동반" "$PLACE_REPO/taste-skill/gpt-taste/LICENSE"
if [ -d "$PLACE_REPO/taste-skill/gpt-taste/.git" ]; then
  echo -e "${RED}FAIL${NC}: .git 제거"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: .git 제거"; PASS=$((PASS+1)); fi

# --- 중첩사고 가드: 재배치해도 dest/gpt-taste 같은 중첩 안 생김 ---
sm_place "$PL_SRC" gpt-taste taste-skill "$PL_LIC" >/dev/null
if [ -e "$PLACE_REPO/taste-skill/gpt-taste/gpt-taste" ]; then
  echo -e "${RED}FAIL${NC}: 재배치 중첩 없음"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 재배치 중첩 없음"; PASS=$((PASS+1)); fi

# --- flat 배치(그룹 없음) ---
pl_flat="$(sm_place "$PL_SRC" minimalist-ui "" "")"
assert_eq "flat dest path" "$PLACE_REPO/minimalist-ui" "$pl_flat"
assert_file_exists "flat placed SKILL.md" "$PLACE_REPO/minimalist-ui/SKILL.md"

# --- 잘못된 invocation name 거부 ---
if sm_place "$PL_SRC" "bad name!" "" "" >/dev/null 2>&1; then
  echo -e "${RED}FAIL${NC}: 잘못된 이름 거부"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 잘못된 이름 거부"; PASS=$((PASS+1)); fi

export SKILLS_REPO="$PL_OLD"
