#!/usr/bin/env bash
# call-it-a-day test runner. Sources hooks/common.sh + each test_*.sh (which use assert helpers).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Isolate state in temp dirs so tests never touch real ~/.claude or vault.
export CALL_IT_A_DAY_HOME="$(mktemp -d)"
export CALL_IT_A_DAY_VAULT="$(mktemp -d)"
trap 'rm -rf "$CALL_IT_A_DAY_HOME" "$CALL_IT_A_DAY_VAULT"' EXIT

source "$PLUGIN_DIR/hooks/common.sh"

PASS=0; FAIL=0
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

assert_eq() {
  local desc="$1" exp="$2" act="$3"
  if [ "$exp" = "$act" ]; then echo -e "${GREEN}PASS${NC}: $desc"; PASS=$((PASS+1));
  else echo -e "${RED}FAIL${NC}: $desc"; echo "  exp: [$exp]"; echo "  act: [$act]"; FAIL=$((FAIL+1)); fi
}
assert_contains() {
  local desc="$1" needle="$2" hay="$3"
  if printf '%s' "$hay" | grep -qF "$needle"; then echo -e "${GREEN}PASS${NC}: $desc"; PASS=$((PASS+1));
  else echo -e "${RED}FAIL${NC}: $desc"; echo "  missing: [$needle]"; FAIL=$((FAIL+1)); fi
}

for t in "$SCRIPT_DIR"/test_*.sh; do
  [ -f "$t" ] || continue
  echo "──── $(basename "$t") ────"
  # shellcheck disable=SC1090
  source "$t"
done

echo "════════ PASS=$PASS  FAIL=$FAIL ════════"
[ "$FAIL" -eq 0 ]
