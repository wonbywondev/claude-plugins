#!/usr/bin/env bash
# run-all.sh
#
# Runs every test-*.sh in this directory against the real shell, streams a
# PASS/FAIL summary to the console, and writes the full combined output to
# tests/last-run.log for later inspection.
#
# Each test is self-isolating (sandboxed HOME via mktemp), so this runner only
# orchestrates and reports — it never touches ~/.claude.
#
# Exit code: 0 if all tests pass, 1 if any test fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/last-run.log"

# Collect tests (sorted, excluding this runner).
shopt -s nullglob
TESTS=()
for t in "$SCRIPT_DIR"/test-*.sh; do
  TESTS+=("$t")
done
shopt -u nullglob

if [[ ${#TESTS[@]} -eq 0 ]]; then
  echo "run-all: no test-*.sh files found in $SCRIPT_DIR" >&2
  exit 1
fi

# Fresh log with a header.
{
  echo "preserve-session test run"
  echo "started: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "shell:   $(bash --version | head -1)"
  echo "tests:   ${#TESTS[@]}"
  echo "========================================"
} > "$LOG"

PASS_COUNT=0
FAIL_COUNT=0
FAILED_NAMES=()

for t in "${TESTS[@]}"; do
  name=$(basename "$t")
  # Capture combined stdout+stderr and the real exit code.
  output=$(bash "$t" 2>&1)
  code=$?

  {
    echo ""
    echo "########## $name (exit $code) ##########"
    echo "$output"
  } >> "$LOG"

  if [[ $code -eq 0 ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  \033[32mPASS\033[0m  %s\n' "$name"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_NAMES+=("$name")
    printf '  \033[31mFAIL\033[0m  %s  (exit %d)\n' "$name" "$code"
    # Surface the last few lines of the failing output inline for quick triage.
    echo "$output" | tail -4 | sed 's/^/        | /'
  fi
done

{
  echo ""
  echo "========================================"
  echo "summary: $PASS_COUNT passed, $FAIL_COUNT failed (of ${#TESTS[@]})"
} >> "$LOG"

echo "------------------------------------------"
echo "  $PASS_COUNT passed, $FAIL_COUNT failed (of ${#TESTS[@]})"
echo "  log: $LOG"

if [[ $FAIL_COUNT -gt 0 ]]; then
  printf '  failed: %s\n' "${FAILED_NAMES[*]}"
  exit 1
fi
exit 0
