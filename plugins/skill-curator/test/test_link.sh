#!/usr/bin/env bash
# Tests for link.sh

LINK="$PLUGIN_DIR/hooks/link.sh"

# ─── link --link (project scope) ─────────────────────────────
bash "$LINK" --link systematic-debugging --scope project --project-dir "$MOCK_PROJECT" 2>/dev/null
assert_symlink "link creates project symlink" "$MOCK_PROJECT/.claude/skills/systematic-debugging"

# ─── link --link (global scope) ──────────────────────────────
bash "$LINK" --link pdf --scope global 2>/dev/null
assert_symlink "link creates global symlink" "$MOCK_GLOBAL/pdf"

# ─── link --link namespaced (project scope) ──────────────────
bash "$LINK" --link notion/knowledge-capture --scope project --project-dir "$MOCK_PROJECT" 2>/dev/null
assert_symlink "link creates namespaced project symlink" "$MOCK_PROJECT/.claude/skills/notion"

# ─── link --status ───────────────────────────────────────────
output="$(bash "$LINK" --status --scope all --project-dir "$MOCK_PROJECT")"
assert_contains "status shows global symlink" "pdf" "$output"
assert_contains "status shows project symlink" "systematic-debugging" "$output"

# ─── link --unlink ───────────────────────────────────────────
bash "$LINK" --unlink pdf --scope global 2>/dev/null
output="$(bash "$LINK" --status --scope global)"
# pdf should no longer appear
if echo "$output" | grep -q "pdf"; then
  echo -e "${RED}FAIL${NC}: unlink removes global symlink"
  FAIL=$((FAIL+1))
else
  echo -e "${GREEN}PASS${NC}: unlink removes global symlink"
  PASS=$((PASS+1))
fi
