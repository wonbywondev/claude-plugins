#!/usr/bin/env bash
# test-fix.sh
#
# TDD + characterization test for fix.sh. Covers the copy-branch slug
# collision guard (H2) AND the rename/move branch (slug-folder migration).
#
# Assertions:
#   (1) fix.sh on a freshly-copied project whose new path collides with an
#       existing registry entry's slug → exits 1 with collision warning,
#       registry unchanged
#   (2) --force overrides the guard → registers the new hash
#   (3) Rename (old path gone, dest folder absent) → the OLD slug folder is
#       renamed to the NEW slug folder (mv), registry updated to the new path
#   (4) Merge (dest folder already exists) → non-conflicting .jsonl files are
#       copied over, same-named files are SKIPPED (not overwritten), the OLD
#       folder is kept as stale, registry updated to the new path
#   (5) No sessions folder for the old path → fix still succeeds and updates
#       the registry (nothing to migrate)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX_SH="$(cd "$SCRIPT_DIR/.." && pwd)/fix.sh"

if [[ ! -f "$FIX_SH" ]]; then
  echo "TEST SETUP ERROR: $FIX_SH not found" >&2
  exit 2
fi

fail() { echo "FAIL: $*" >&2; exit 1; }

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

# Set up registry with an "original" entry whose slug will collide with NEW_DIR.
# Using /foo-bar vs /foo/bar: both slug to -foo-bar.
ORIG_DIR="$FAKE_HOME/collide-src"       # original alive project
NEW_DIR="$FAKE_HOME/collide/src"         # new copy, will collide slug with ORIG_DIR

mkdir -p "$ORIG_DIR/.claude" "$NEW_DIR/.claude"
mkdir -p "$FAKE_HOME/.claude/projects"

H_ORIG="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
H_NEW="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

echo "$H_ORIG" > "$ORIG_DIR/.claude/hash.txt"
echo "$H_NEW"  > "$NEW_DIR/.claude/hash.txt"

# Registry has only ORIG_DIR; NEW_DIR's hash is present on disk but not in
# registry (typical "just copied the project, haven't run /fix yet" state).
REGISTRY="$FAKE_HOME/.claude/project-registry.json"
"$PY" -c "
import json
open('$REGISTRY', 'w').write(json.dumps({'$H_ORIG': '$ORIG_DIR'}, indent=2))
"

# Sanity check: the two paths really do share a slug
_slug() {
  "$PY" -c "import re, sys, unicodedata; print(re.sub(r'[^a-zA-Z0-9-]', '-', unicodedata.normalize('NFC', sys.argv[1])))" "$1"
}
[[ "$(_slug "$ORIG_DIR")" == "$(_slug "$NEW_DIR")" ]] \
  || fail "TEST SETUP: paths do not share a slug"

# --- Assertion 1: fix.sh without --force in NEW_DIR → exits 1, warns, no registry change ---

set +e
OUTPUT=$(cd "$NEW_DIR" && HOME="$FAKE_HOME" bash "$FIX_SH" 2>&1)
EXIT_CODE=$?
set -e

[[ $EXIT_CODE -eq 1 ]] \
  || fail "expected exit 1 on collision without --force, got $EXIT_CODE. Output:
$OUTPUT"

echo "$OUTPUT" | grep -q "slug collision detected" \
  || fail "expected collision warning, got:
$OUTPUT"

REG_AFTER=$("$PY" -c "import json; print(len(json.load(open('$REGISTRY'))))")
[[ "$REG_AFTER" -eq 1 ]] \
  || fail "registry should still have exactly 1 entry, got $REG_AFTER"

# --- Assertion 2: fix.sh --force in NEW_DIR → registers NEW_DIR ---

OUTPUT=$(cd "$NEW_DIR" && HOME="$FAKE_HOME" bash "$FIX_SH" --force 2>&1)

echo "$OUTPUT" | grep -q "Proceeding with --force" \
  || fail "expected '--force' path to proceed, got:
$OUTPUT"

REG_ENTRIES=$("$PY" -c "import json; print(len(json.load(open('$REGISTRY'))))")
[[ "$REG_ENTRIES" -eq 2 ]] \
  || fail "registry should have 2 entries after --force, got $REG_ENTRIES"

# Verify the new entry in registry points to NEW_DIR
HAS_NEW=$("$PY" -c "
import json
d = json.load(open('$REGISTRY'))
print('yes' if '$NEW_DIR' in d.values() else 'no')
")
[[ "$HAS_NEW" == "yes" ]] \
  || fail "NEW_DIR not registered after --force"

# ---------------------------------------------------------------------------
# Shared helpers for the rename/move scenarios below.
# ---------------------------------------------------------------------------

PROJECTS="$FAKE_HOME/.claude/projects"

_write_single_registry() {
  # $1 = hash, $2 = path → registry with exactly one entry (isolates each
  # scenario from sibling slug collisions left over by earlier blocks).
  PRESERVE_H="$1" PRESERVE_P="$2" PRESERVE_REG="$REGISTRY" "$PY" - <<'PYEOF'
import json, os
json.dump({os.environ["PRESERVE_H"]: os.environ["PRESERVE_P"]},
          open(os.environ["PRESERVE_REG"], "w"), indent=2)
PYEOF
}

_registry_value() {
  # Print registry[$1]
  PRESERVE_H="$1" PRESERVE_REG="$REGISTRY" "$PY" - <<'PYEOF'
import json, os
d = json.load(open(os.environ["PRESERVE_REG"]))
print(d.get(os.environ["PRESERVE_H"], ""))
PYEOF
}

# --- Assertion 3: clean rename (old path gone, dest folder absent) ---

H3="cccccccc-cccc-cccc-cccc-cccccccccccc"
OLD3="$FAKE_HOME/proj-old-3"
mkdir -p "$OLD3/.claude"
OLD3=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$OLD3")
echo "$H3" > "$OLD3/.claude/hash.txt"
_write_single_registry "$H3" "$OLD3"

# Seed the OLD slug folder with one session file.
OLD3_SLUG=$(_slug "$OLD3")
mkdir -p "$PROJECTS/$OLD3_SLUG"
echo '{"type":"last-prompt","sessionId":"s3"}' > "$PROJECTS/$OLD3_SLUG/session3.jsonl"

# Physically move the project (hash.txt travels); old path now gone.
NEW3="$FAKE_HOME/proj-new-3"
mv "$OLD3" "$NEW3"
NEW3=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$NEW3")
NEW3_SLUG=$(_slug "$NEW3")

set +e
OUTPUT=$(cd "$NEW3" && HOME="$FAKE_HOME" bash "$FIX_SH" 2>&1)
EXIT_CODE=$?
set -e

[[ $EXIT_CODE -eq 0 ]] \
  || fail "rename: expected exit 0, got $EXIT_CODE. Output:
$OUTPUT"
echo "$OUTPUT" | grep -q "detected rename/move" \
  || fail "rename: expected 'detected rename/move'. Output:
$OUTPUT"
[[ ! -d "$PROJECTS/$OLD3_SLUG" ]] \
  || fail "rename: OLD slug folder should have been moved away, still exists: $PROJECTS/$OLD3_SLUG"
[[ -f "$PROJECTS/$NEW3_SLUG/session3.jsonl" ]] \
  || fail "rename: session file not found in NEW slug folder $PROJECTS/$NEW3_SLUG"
[[ "$(_registry_value "$H3")" == "$NEW3" ]] \
  || fail "rename: registry[$H3] = '$(_registry_value "$H3")', expected '$NEW3'"

# --- Assertion 4: merge into an existing destination folder (+ skip conflict) ---

H4="dddddddd-dddd-dddd-dddd-dddddddddddd"
OLD4="$FAKE_HOME/proj-old-4"
mkdir -p "$OLD4/.claude"
OLD4=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$OLD4")
echo "$H4" > "$OLD4/.claude/hash.txt"
_write_single_registry "$H4" "$OLD4"

OLD4_SLUG=$(_slug "$OLD4")
mkdir -p "$PROJECTS/$OLD4_SLUG"
# Old folder: one unique file + one that will conflict by name.
echo '{"src":"old","f":"A"}'   > "$PROJECTS/$OLD4_SLUG/A.jsonl"
echo '{"src":"old","f":"dup"}' > "$PROJECTS/$OLD4_SLUG/dup.jsonl"

# Move project, then pre-create the destination folder with a same-named file.
NEW4="$FAKE_HOME/proj-new-4"
mv "$OLD4" "$NEW4"
NEW4=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$NEW4")
NEW4_SLUG=$(_slug "$NEW4")
mkdir -p "$PROJECTS/$NEW4_SLUG"
echo '{"src":"new","f":"dup"}' > "$PROJECTS/$NEW4_SLUG/dup.jsonl"   # pre-existing → must be kept

set +e
OUTPUT=$(cd "$NEW4" && HOME="$FAKE_HOME" bash "$FIX_SH" 2>&1)
EXIT_CODE=$?
set -e

[[ $EXIT_CODE -eq 0 ]] \
  || fail "merge: expected exit 0, got $EXIT_CODE. Output:
$OUTPUT"
echo "$OUTPUT" | grep -q "sessions merged: 1 copied, 1 skipped" \
  || fail "merge: expected '1 copied, 1 skipped'. Output:
$OUTPUT"
# Unique file copied over.
[[ -f "$PROJECTS/$NEW4_SLUG/A.jsonl" ]] \
  || fail "merge: A.jsonl was not copied into the destination"
# Conflicting file NOT overwritten (destination's content preserved).
grep -q '"src":"new"' "$PROJECTS/$NEW4_SLUG/dup.jsonl" \
  || fail "merge: dup.jsonl was overwritten — destination copy must be preserved"
# Old folder kept as stale.
[[ -d "$PROJECTS/$OLD4_SLUG" ]] \
  || fail "merge: OLD slug folder should be kept as stale, but it is gone"
[[ "$(_registry_value "$H4")" == "$NEW4" ]] \
  || fail "merge: registry[$H4] = '$(_registry_value "$H4")', expected '$NEW4'"

# --- Assertion 5: rename with no sessions folder for the old path ---

H5="eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
OLD5="$FAKE_HOME/proj-old-5"
mkdir -p "$OLD5/.claude"
OLD5=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$OLD5")
echo "$H5" > "$OLD5/.claude/hash.txt"
_write_single_registry "$H5" "$OLD5"
# Intentionally do NOT create a slug folder for OLD5.

NEW5="$FAKE_HOME/proj-new-5"
mv "$OLD5" "$NEW5"
NEW5=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$NEW5")

set +e
OUTPUT=$(cd "$NEW5" && HOME="$FAKE_HOME" bash "$FIX_SH" 2>&1)
EXIT_CODE=$?
set -e

[[ $EXIT_CODE -eq 0 ]] \
  || fail "no-sessions: expected exit 0, got $EXIT_CODE. Output:
$OUTPUT"
echo "$OUTPUT" | grep -q "no sessions folder found" \
  || fail "no-sessions: expected 'no sessions folder found'. Output:
$OUTPUT"
[[ "$(_registry_value "$H5")" == "$NEW5" ]] \
  || fail "no-sessions: registry[$H5] = '$(_registry_value "$H5")', expected '$NEW5'"

echo "PASS"
