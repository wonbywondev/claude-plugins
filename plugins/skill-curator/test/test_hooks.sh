#!/usr/bin/env bash
# Tests for session-start.sh and post-plan.sh hooks

HOOKS_DIR="$PLUGIN_DIR/hooks"

# ─── session-start.sh ────────────────────────────────────────

# Should output recommendation for n8n project
PROJ_N8N="$TMPDIR_ROOT/hook-proj-n8n"
mkdir -p "$PROJ_N8N"/.claude/skills
echo '{"name":"my-n8n-nodes"}' > "$PROJ_N8N/package.json"
touch "$PROJ_N8N/.n8nrc"
output="$(cd "$PROJ_N8N" && bash "$HOOKS_DIR/session-start.sh" 2>&1)"
assert_contains "session-start detects n8n stack" "n8n" "$output"
assert_contains "session-start recommends skills" "n8n/" "$output"

# Should be silent for already-curated project (has symlinks)
PROJ_CURATED="$TMPDIR_ROOT/hook-proj-curated"
mkdir -p "$PROJ_CURATED"/.claude/skills
ln -s "$MOCK_CENTRAL/notion" "$PROJ_CURATED/.claude/skills/notion"
output="$(cd "$PROJ_CURATED" && bash "$HOOKS_DIR/session-start.sh" 2>&1)"
assert_eq "session-start silent for curated project" "" "$output"

# Should be silent for empty project (no stack detected)
PROJ_NONE="$TMPDIR_ROOT/hook-proj-none"
mkdir -p "$PROJ_NONE"
output="$(cd "$PROJ_NONE" && bash "$HOOKS_DIR/session-start.sh" 2>&1)"
assert_eq "session-start silent for unknown stack" "" "$output"

# ─── post-plan.sh ────────────────────────────────────────────

# Should trigger when recent plan file exists
PROJ_PLAN="$TMPDIR_ROOT/hook-proj-plan"
mkdir -p "$PROJ_PLAN"/.claude/plans
echo '{"name":"test-project","dependencies":{"@notionhq/client":"2.0"}}' > "$PROJ_PLAN/package.json"
echo "# Test plan" > "$PROJ_PLAN/.claude/plans/test-plan.md"
# touch with current time (just created, so mtime is now)
output="$(cd "$PROJ_PLAN" && bash "$HOOKS_DIR/post-plan.sh" 2>&1)"
assert_contains "post-plan triggers on recent plan" "skill-curator" "$output"

# Should not trigger again (offered marker exists)
output="$(cd "$PROJ_PLAN" && bash "$HOOKS_DIR/post-plan.sh" 2>&1)"
assert_eq "post-plan does not re-trigger" "" "$output"

# Cleanup marker for further tests
rm -f "$PROJ_PLAN/.claude/.skill-curator-offered"

# Should be silent when no plan files
PROJ_NOPLAN="$TMPDIR_ROOT/hook-proj-noplan"
mkdir -p "$PROJ_NOPLAN"/.claude
output="$(cd "$PROJ_NOPLAN" && bash "$HOOKS_DIR/post-plan.sh" 2>&1)"
assert_eq "post-plan silent without plans" "" "$output"
