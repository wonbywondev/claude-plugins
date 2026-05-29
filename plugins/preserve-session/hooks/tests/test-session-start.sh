#!/usr/bin/env bash
# test-session-start.sh
#
# Integration test for session-start.sh — the core SessionStart hook that
# every `claude` invocation runs. Verifies the path-independent session
# tracking contract end-to-end against a sandboxed HOME.
#
# Assertions:
#   (1) Fresh init: a project with no hash.txt → hash.txt created with a
#       valid UUID, and registry maps that hash → the project's realpath
#   (2) Idempotent: a second run in the same project leaves hash.txt
#       unchanged (same UUID) and the registry at exactly 1 entry
#   (3) Re-register: hash.txt present but its hash absent from the registry
#       (e.g. registry reset) → the hash is re-registered to the project path
#   (4) Move boundary (early-exit contract): when a project directory is moved
#       (hash.txt travels with it) but the hash is STILL registered to the old
#       path, session-start does NOT rewrite the path — it early-exits. Keeping
#       the old path is intentional: /preserve-session:fix needs it to locate
#       the old slug folder and migrate sessions. session-start owns init +
#       idempotency + re-register-when-missing; fix.sh owns move completion.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SS_SH="$(cd "$SCRIPT_DIR/.." && pwd)/session-start.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ ! -f "$SS_SH" ]]; then
  echo "TEST SETUP ERROR: $SS_SH not found" >&2
  exit 2
fi

_pick_python() {
  for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1; then echo "$c"; return 0; fi
  done
  echo "TEST SETUP ERROR: no python available" >&2; exit 2
}
PY=$(_pick_python)

FAKE_HOME_RAW=$(mktemp -d)
trap 'rm -rf "$FAKE_HOME_RAW"' EXIT
FAKE_HOME=$("$PY" -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$FAKE_HOME_RAW")

mkdir -p "$FAKE_HOME/.claude"
REGISTRY="$FAKE_HOME/.claude/project-registry.json"

_run_hook() {
  # Run session-start.sh with $1 as the working directory and the sandboxed HOME.
  (cd "$1" && HOME="$FAKE_HOME" bash "$SS_SH")
}

_registry_get() {
  # Print the registry value for hash $1 (empty string if absent/missing file).
  PRESERVE_REGISTRY="$REGISTRY" PRESERVE_HASH="$1" "$PY" - <<'PYEOF'
import json, os
try:
    with open(os.environ["PRESERVE_REGISTRY"]) as f:
        r = json.load(f)
except (FileNotFoundError, json.JSONDecodeError, ValueError):
    r = {}
print(r.get(os.environ["PRESERVE_HASH"], "") if isinstance(r, dict) else "")
PYEOF
}

_registry_count() {
  PRESERVE_REGISTRY="$REGISTRY" "$PY" - <<'PYEOF'
import json, os
try:
    with open(os.environ["PRESERVE_REGISTRY"]) as f:
        r = json.load(f)
except (FileNotFoundError, json.JSONDecodeError, ValueError):
    r = {}
print(len(r) if isinstance(r, dict) else 0)
PYEOF
}

# --- Assertion 1: fresh init ---

PROJ_A="$FAKE_HOME/work/projA"
mkdir -p "$PROJ_A"
PROJ_A=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ_A")

_run_hook "$PROJ_A"

HASH_FILE_A="$PROJ_A/.claude/hash.txt"
[[ -f "$HASH_FILE_A" ]] || fail "fresh init did not create hash.txt at $HASH_FILE_A"

HASH_A=$(cat "$HASH_FILE_A")
# UUID format check (8-4-4-4-12 hex)
"$PY" -c "import re,sys; sys.exit(0 if re.fullmatch(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', sys.argv[1]) else 1)" "$HASH_A" \
  || fail "hash.txt content is not a valid UUID: '$HASH_A'"

REG_A=$(_registry_get "$HASH_A")
[[ "$REG_A" == "$PROJ_A" ]] \
  || fail "fresh init: registry[$HASH_A] = '$REG_A', expected '$PROJ_A'"

# --- Assertion 2: idempotent re-run ---

_run_hook "$PROJ_A"

HASH_A2=$(cat "$HASH_FILE_A")
[[ "$HASH_A2" == "$HASH_A" ]] \
  || fail "idempotent re-run changed hash: was '$HASH_A', now '$HASH_A2'"

COUNT=$(_registry_count)
[[ "$COUNT" -eq 1 ]] \
  || fail "idempotent re-run: expected 1 registry entry, got $COUNT"

# --- Assertion 3: re-register when registry entry is missing ---

# Reset the registry to empty (hash.txt stays in the project)
printf '%s' '{}' > "$REGISTRY"

_run_hook "$PROJ_A"

REG_A3=$(_registry_get "$HASH_A")
[[ "$REG_A3" == "$PROJ_A" ]] \
  || fail "re-register: registry[$HASH_A] = '$REG_A3', expected '$PROJ_A' after reset"

# hash.txt must still be the original UUID (not regenerated)
HASH_A3=$(cat "$HASH_FILE_A")
[[ "$HASH_A3" == "$HASH_A" ]] \
  || fail "re-register regenerated the hash: was '$HASH_A', now '$HASH_A3'"

# --- Assertion 4: move boundary (early-exit contract) ---

PROJ_B="$FAKE_HOME/work/projB"
# Move the whole project (hash.txt travels with it, as in a real `mv`)
mv "$PROJ_A" "$PROJ_B"
PROJ_B=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ_B")

_run_hook "$PROJ_B"

# session-start must NOT rewrite the path: the hash is still registered (to the
# old path), so the hook early-exits. registry[hash] stays at the OLD path —
# this is the precondition /preserve-session:fix later repairs.
REG_B=$(_registry_get "$HASH_A")
[[ "$REG_B" == "$PROJ_A" ]] \
  || fail "move boundary: registry[$HASH_A] = '$REG_B', expected it to STAY at old path '$PROJ_A' (path migration is fix.sh's job, not session-start's)"

# The new path must NOT have been auto-registered by session-start.
NEW_PRESENT=$(PRESERVE_REGISTRY="$REGISTRY" PRESERVE_NEW="$PROJ_B" "$PY" - <<'PYEOF'
import json, os
with open(os.environ["PRESERVE_REGISTRY"]) as f:
    r = json.load(f)
print("yes" if os.environ["PRESERVE_NEW"] in r.values() else "no")
PYEOF
)
[[ "$NEW_PRESENT" == "no" ]] \
  || fail "move boundary: new path '$PROJ_B' was auto-registered by session-start (should wait for fix.sh)"

# Still exactly one entry (no duplicate created by the move).
COUNT=$(_registry_count)
[[ "$COUNT" -eq 1 ]] \
  || fail "move boundary: expected 1 registry entry after move, got $COUNT"

echo "PASS"
