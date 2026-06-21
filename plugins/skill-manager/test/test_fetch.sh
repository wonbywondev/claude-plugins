# Phase 2 — fetch (가져오기·enumeration)

FETCH_T="$TMPDIR_ROOT/fetch"; mkdir -p "$FETCH_T"

# --- frontmatter: single-line ---
mkdir -p "$FETCH_T/single"
printf -- '---\nname: my-skill\ndescription: Use when you need a single line desc.\n---\nbody\n' > "$FETCH_T/single/SKILL.md"
assert_eq "frontmatter name (single-line)" "my-skill" "$(sm_frontmatter_field "$FETCH_T/single/SKILL.md" name)"
assert_eq "frontmatter description (single-line)" "Use when you need a single line desc." "$(sm_frontmatter_field "$FETCH_T/single/SKILL.md" description)"

# --- frontmatter: folded multi-line description ---
mkdir -p "$FETCH_T/folded"
{
  printf -- '---\n'
  printf -- 'name: folded-skill\n'
  printf -- 'description: >\n'
  printf -- '  First line of folded.\n'
  printf -- '  Second line of folded.\n'
  printf -- '---\nbody\n'
} > "$FETCH_T/folded/SKILL.md"
assert_eq "frontmatter description (folded)" "First line of folded. Second line of folded." "$(sm_frontmatter_field "$FETCH_T/folded/SKILL.md" description)"
assert_eq "frontmatter name (with folded desc after)" "folded-skill" "$(sm_frontmatter_field "$FETCH_T/folded/SKILL.md" name)"

# --- candidates: skills/<name>, flat <name>, nested ref excluded, dangling excluded ---
REPO="$TMPDIR_ROOT/fetch-repo"
mkdir -p "$REPO/skills/alpha" "$REPO/beta/refs" "$REPO/brokendir"
printf -- '---\nname: alpha\ndescription: A.\n---\n' > "$REPO/skills/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: B.\n---\n' > "$REPO/beta/SKILL.md"
printf -- '---\nname: ref\ndescription: nested ref.\n---\n' > "$REPO/beta/refs/SKILL.md"
ln -s /nonexistent/SKILL.md "$REPO/brokendir/SKILL.md"
cand="$(sm_fetch_candidates "$REPO")"
assert_eq "candidate count (alpha+beta; refs/dangling 제외)" "2" "$(printf '%s\n' "$cand" | grep -c .)"
assert_contains "candidate alpha (skills/ 컨벤션)" "alpha" "$cand"
assert_contains "candidate beta (flat)" "beta" "$cand"
if printf '%s\n' "$cand" | grep -q "nested ref"; then
  echo -e "${RED}FAIL${NC}: nested ref 제외"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: nested ref 제외"; PASS=$((PASS+1)); fi

# --- root-skill repo: only root candidate ---
ROOT="$TMPDIR_ROOT/fetch-root"; mkdir -p "$ROOT/refs"
printf -- '---\nname: rootskill\ndescription: R.\n---\n' > "$ROOT/SKILL.md"
printf -- '---\nname: ref2\ndescription: r2.\n---\n' > "$ROOT/refs/SKILL.md"
rc="$(sm_fetch_candidates "$ROOT")"
assert_eq "root-skill repo: 1 candidate" "1" "$(printf '%s\n' "$rc" | grep -c .)"
assert_contains "root-skill candidate name" "rootskill" "$rc"

# --- umbrella layout: root SKILL.md + ≥2 child skills (gstack 패턴) ---
UMB="$TMPDIR_ROOT/umbrella"
mkdir -p "$UMB/autoplan" "$UMB/browse" "$UMB/qa/refs"
printf -- '---\nname: gstack\ndescription: umbrella browser QA.\n---\n' > "$UMB/SKILL.md"
printf -- '---\nname: autoplan\ndescription: a.\n---\n' > "$UMB/autoplan/SKILL.md"
printf -- '---\nname: browse\ndescription: b.\n---\n' > "$UMB/browse/SKILL.md"
printf -- '---\nname: qa\ndescription: q.\n---\n' > "$UMB/qa/SKILL.md"
printf -- '---\nname: qaref\ndescription: nested ref under leaf.\n---\n' > "$UMB/qa/refs/SKILL.md"
umb_cand="$(sm_fetch_candidates "$UMB")"
assert_eq "umbrella: root + 3 children = 4" "4" "$(printf '%s\n' "$umb_cand" | grep -c .)"
assert_contains "umbrella root counted" "gstack" "$umb_cand"
assert_contains "umbrella child autoplan" "autoplan" "$umb_cand"
assert_contains "umbrella child qa" "qa" "$umb_cand"
if printf '%s\n' "$umb_cand" | grep -q "nested ref under leaf"; then
  echo -e "${RED}FAIL${NC}: leaf 하위 ref는 제외"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: leaf 하위 ref는 제외"; PASS=$((PASS+1)); fi

# --- clone: local path copies, strips .git ---
SRCD="$TMPDIR_ROOT/clone-src"; mkdir -p "$SRCD/.git" "$SRCD/x"
printf -- '---\nname: x\ndescription: X.\n---\n' > "$SRCD/x/SKILL.md"
DSTD="$TMPDIR_ROOT/clone-dst"
sm_fetch_clone "$SRCD" "$DSTD" >/dev/null 2>&1
assert_file_exists "clone copies skill" "$DSTD/x/SKILL.md"
if [ -d "$DSTD/.git" ]; then echo -e "${RED}FAIL${NC}: clone strips .git"; FAIL=$((FAIL+1)); else echo -e "${GREEN}PASS${NC}: clone strips .git"; PASS=$((PASS+1)); fi
