#!/usr/bin/env bash
# Minimal test runner for skill-curator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}PASS${NC}: $desc"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC}: $desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo -e "${GREEN}PASS${NC}: $desc"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC}: $desc"
    echo "  expected to contain: $needle"
    echo "  actual: $haystack"
    FAIL=$((FAIL+1))
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -e "$path" ]; then
    echo -e "${GREEN}PASS${NC}: $desc"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC}: $desc (file not found: $path)"
    FAIL=$((FAIL+1))
  fi
}

assert_symlink() {
  local desc="$1" path="$2"
  if [ -L "$path" ]; then
    echo -e "${GREEN}PASS${NC}: $desc"
    PASS=$((PASS+1))
  else
    echo -e "${RED}FAIL${NC}: $desc (not a symlink: $path)"
    FAIL=$((FAIL+1))
  fi
}

# ─── Setup temp environment ─────────────────────────────────
TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

MOCK_CENTRAL="$TMPDIR_ROOT/central-skills"
MOCK_GLOBAL="$TMPDIR_ROOT/global-skills"
MOCK_PROJECT="$TMPDIR_ROOT/project"

mkdir -p "$MOCK_CENTRAL"/{systematic-debugging,test-driven-development,pdf}
mkdir -p "$MOCK_CENTRAL"/notion/{knowledge-capture,meeting-intelligence}
mkdir -p "$MOCK_CENTRAL"/n8n/{code-python,node-configuration}
mkdir -p "$MOCK_CENTRAL"/gstack-qa
mkdir -p "$MOCK_GLOBAL"
mkdir -p "$MOCK_PROJECT"/.claude/skills

# Create mock SKILL.md files
for d in "$MOCK_CENTRAL"/*/; do
  [ -d "$d" ] && touch "$d/SKILL.md" 2>/dev/null || true
done
for d in "$MOCK_CENTRAL"/notion/*/; do
  touch "$d/SKILL.md"
done
for d in "$MOCK_CENTRAL"/n8n/*/; do
  touch "$d/SKILL.md"
done

# Export env vars for common.sh
export SKILLS_REPO="$MOCK_CENTRAL"
export GLOBAL_SKILLS_DIR="$MOCK_GLOBAL"

# Source common.sh
source "$PLUGIN_DIR/hooks/common.sh"

# ─── Run test files ──────────────────────────────────────────
for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [ -f "$test_file" ] || continue
  echo ""
  echo "=== $(basename "$test_file") ==="
  source "$test_file"
done

# ─── Summary ─────────────────────────────────────────────────
echo ""
echo "────────────────────────"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
