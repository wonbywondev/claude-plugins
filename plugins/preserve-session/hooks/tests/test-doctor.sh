#!/usr/bin/env bash
# test-doctor.sh
#
# Characterization test for doctor.sh — verifies the diagnostic output for the
# distinct project states the command is meant to report. doctor.sh is
# read-only (no mutations), so these assertions grep its stdout.
#
# Assertions:
#   (1) Healthy: hash.txt present + registered + path match → reports
#       ✓ hash.txt, ✓ registry registered, ✓ path match, and a Registry health
#       section
#   (2) Missing hash.txt → ✗ hash.txt Missing, exits 0
#   (3) Hash present but not in registry → ✗ registry Hash not registered
#   (4) Path mismatch (registry points elsewhere) → ✗ path match + fix hint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCTOR_SH="$(cd "$SCRIPT_DIR/.." && pwd)/doctor.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ ! -f "$DOCTOR_SH" ]]; then
  echo "TEST SETUP ERROR: $DOCTOR_SH not found" >&2
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

_run_doctor() {
  # Run doctor.sh in directory $1 with the sandboxed HOME; never abort the test
  # on doctor's own exit code (it exits 1 when the registry file is absent).
  set +e
  (cd "$1" && HOME="$FAKE_HOME" bash "$DOCTOR_SH" 2>&1)
  set -e
}

_write_registry() {
  # $1 = hash, $2 = path  → single-entry registry
  PRESERVE_H="$1" PRESERVE_P="$2" PRESERVE_REG="$REGISTRY" "$PY" - <<'PYEOF'
import json, os
json.dump({os.environ["PRESERVE_H"]: os.environ["PRESERVE_P"]},
          open(os.environ["PRESERVE_REG"], "w"), indent=2)
PYEOF
}

HASH="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

# --- Assertion 1: healthy state ---

PROJ="$FAKE_HOME/work/healthy"
mkdir -p "$PROJ/.claude"
PROJ=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ")
echo "$HASH" > "$PROJ/.claude/hash.txt"
_write_registry "$HASH" "$PROJ"

OUT=$(_run_doctor "$PROJ")
grep -q "✓  hash.txt" <<<"$OUT" \
  || fail "healthy: missing '✓  hash.txt' line. Got:
$OUT"
grep -q "registry       registered" <<<"$OUT" \
  || fail "healthy: missing 'registry registered' line. Got:
$OUT"
grep -q "✓  path match" <<<"$OUT" \
  || fail "healthy: missing '✓  path match' line. Got:
$OUT"
grep -q "Registry health" <<<"$OUT" \
  || fail "healthy: missing 'Registry health' section. Got:
$OUT"

# --- Assertion 2: missing hash.txt ---

PROJ2="$FAKE_HOME/work/nohash"
mkdir -p "$PROJ2"
PROJ2=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ2")

OUT2=$(_run_doctor "$PROJ2")
grep -q "✗  hash.txt       Missing" <<<"$OUT2" \
  || fail "missing-hash: expected '✗  hash.txt Missing'. Got:
$OUT2"

# --- Assertion 3: hash present but not registered ---

PROJ3="$FAKE_HOME/work/unregistered"
mkdir -p "$PROJ3/.claude"
PROJ3=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ3")
echo "$HASH" > "$PROJ3/.claude/hash.txt"
# Registry exists but holds a DIFFERENT hash → this project's hash is unregistered
_write_registry "ffffffff-0000-0000-0000-000000000000" "/somewhere/else"

OUT3=$(_run_doctor "$PROJ3")
grep -q "Hash not registered" <<<"$OUT3" \
  || fail "unregistered: expected 'Hash not registered'. Got:
$OUT3"

# --- Assertion 4: path mismatch ---

PROJ4="$FAKE_HOME/work/mismatch"
mkdir -p "$PROJ4/.claude"
PROJ4=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ4")
echo "$HASH" > "$PROJ4/.claude/hash.txt"
# Same hash registered, but pointing at a stale/different path
_write_registry "$HASH" "$FAKE_HOME/work/some-old-path"

OUT4=$(_run_doctor "$PROJ4")
grep -q "✗  path match" <<<"$OUT4" \
  || fail "mismatch: expected '✗  path match'. Got:
$OUT4"
grep -q "preserve-session:fix" <<<"$OUT4" \
  || fail "mismatch: expected a fix hint. Got:
$OUT4"

echo "PASS"
