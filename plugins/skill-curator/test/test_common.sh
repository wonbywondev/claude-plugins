#!/usr/bin/env bash
# Tests for common.sh helpers

# ─── list_central_skills ─────────────────────────────────────
output="$(list_central_skills)"
assert_contains "list_central_skills includes flat skills" "systematic-debugging" "$output"
assert_contains "list_central_skills includes namespaced skills" "notion/knowledge-capture" "$output"
assert_contains "list_central_skills includes n8n namespace" "n8n/code-python" "$output"
assert_contains "list_central_skills includes gstack" "gstack-qa" "$output"

# ─── detect_stack ────────────────────────────────────────────
PROJ_NODE="$TMPDIR_ROOT/proj-node"
mkdir -p "$PROJ_NODE"
echo '{"dependencies":{"next":"14.0.0"}}' > "$PROJ_NODE/package.json"
output="$(detect_stack "$PROJ_NODE")"
assert_contains "detect_stack finds node" "node" "$output"

PROJ_PYTHON="$TMPDIR_ROOT/proj-python"
mkdir -p "$PROJ_PYTHON"
touch "$PROJ_PYTHON/requirements.txt"
output="$(detect_stack "$PROJ_PYTHON")"
assert_contains "detect_stack finds python" "python" "$output"

PROJ_N8N="$TMPDIR_ROOT/proj-n8n"
mkdir -p "$PROJ_N8N"
echo '{"name":"my-n8n-nodes"}' > "$PROJ_N8N/package.json"
touch "$PROJ_N8N/.n8nrc"
output="$(detect_stack "$PROJ_N8N")"
assert_contains "detect_stack finds n8n" "n8n" "$output"

PROJ_NOTION="$TMPDIR_ROOT/proj-notion"
mkdir -p "$PROJ_NOTION"
echo '{"dependencies":{"@notionhq/client":"2.0.0"}}' > "$PROJ_NOTION/package.json"
output="$(detect_stack "$PROJ_NOTION")"
assert_contains "detect_stack finds notion" "notion" "$output"

PROJ_EMPTY="$TMPDIR_ROOT/proj-empty"
mkdir -p "$PROJ_EMPTY"
output="$(detect_stack "$PROJ_EMPTY")"
assert_eq "detect_stack returns empty for unknown project" "" "$output"

# ─── match_skills ────────────────────────────────────────────
output="$(match_skills "node")"
assert_eq "match_skills for node returns empty (no node-specific skills)" "" "$output"

output="$(match_skills "n8n")"
assert_contains "match_skills for n8n returns n8n namespace" "n8n/code-python" "$output"

output="$(match_skills "notion")"
assert_contains "match_skills for notion returns notion namespace" "notion/knowledge-capture" "$output"
