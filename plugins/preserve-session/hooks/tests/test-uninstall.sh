#!/usr/bin/env bash
# test-uninstall.sh
#
# Hermetic test for uninstall.sh — verifies preview is non-destructive, that
# --confirm removes registry + hash.txt files, and that symlinked hash.txt
# entries are never deleted. Runs entirely against a sandboxed HOME.
#
# Assertions:
#   (1) Preview (no --confirm): prints the deletion plan but changes nothing —
#       registry and all hash.txt files still exist afterwards
#   (2) --confirm: deletes the registry and every regular hash.txt, prints
#       "Done."
#   (3) Symlink safety: a hash.txt that is a symlink is SKIPped (its target
#       survives), while regular hash.txt files are still deleted
#   (4) No registry file → "nothing to uninstall", exit 0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_SH="$(cd "$SCRIPT_DIR/.." && pwd)/uninstall.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ ! -f "$UNINSTALL_SH" ]]; then
  echo "TEST SETUP ERROR: $UNINSTALL_SH not found" >&2
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

_run_uninstall() {
  # $1 (optional) = --confirm ; never abort the test on uninstall's exit code
  set +e
  HOME="$FAKE_HOME" bash "$UNINSTALL_SH" "$@" 2>&1
  set -e
}

# Build a registry with two regular projects + write their hash.txt files.
PROJ1="$FAKE_HOME/work/p1"; mkdir -p "$PROJ1/.claude"
PROJ2="$FAKE_HOME/work/p2"; mkdir -p "$PROJ2/.claude"
PROJ1=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ1")
PROJ2=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ2")
echo "11111111-1111-1111-1111-111111111111" > "$PROJ1/.claude/hash.txt"
echo "22222222-2222-2222-2222-222222222222" > "$PROJ2/.claude/hash.txt"

_rebuild_registry() {
  PRESERVE_REG="$REGISTRY" P1="$PROJ1" P2="$PROJ2" "$PY" - <<'PYEOF'
import json, os
json.dump({
    "11111111-1111-1111-1111-111111111111": os.environ["P1"],
    "22222222-2222-2222-2222-222222222222": os.environ["P2"],
}, open(os.environ["PRESERVE_REG"], "w"), indent=2)
PYEOF
}
_rebuild_registry

# --- Assertion 1: preview is non-destructive ---

OUT=$(_run_uninstall)
grep -q "permanently deleted" <<<"$OUT" \
  || fail "preview: expected deletion-plan header. Got:
$OUT"
[[ -f "$REGISTRY" ]]            || fail "preview deleted the registry (should be non-destructive)"
[[ -f "$PROJ1/.claude/hash.txt" ]] || fail "preview deleted p1 hash.txt"
[[ -f "$PROJ2/.claude/hash.txt" ]] || fail "preview deleted p2 hash.txt"

# --- Assertion 2: --confirm deletes registry + regular hash.txt files ---

OUT=$(_run_uninstall --confirm)
grep -q "Done." <<<"$OUT" \
  || fail "--confirm: expected 'Done.' Got:
$OUT"
[[ ! -f "$REGISTRY" ]]              || fail "--confirm did not delete the registry"
[[ ! -f "$PROJ1/.claude/hash.txt" ]] || fail "--confirm did not delete p1 hash.txt"
[[ ! -f "$PROJ2/.claude/hash.txt" ]] || fail "--confirm did not delete p2 hash.txt"

# --- Assertion 3: symlink safety ---

# Recreate p1 (regular) and a p3 whose hash.txt is a SYMLINK to a sentinel file.
mkdir -p "$PROJ1/.claude"
echo "11111111-1111-1111-1111-111111111111" > "$PROJ1/.claude/hash.txt"

PROJ3="$FAKE_HOME/work/p3"; mkdir -p "$PROJ3/.claude"
PROJ3=$("$PY" -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$PROJ3")
SENTINEL="$FAKE_HOME/work/sentinel-hash.txt"
echo "33333333-3333-3333-3333-333333333333" > "$SENTINEL"
ln -s "$SENTINEL" "$PROJ3/.claude/hash.txt"

PRESERVE_REG="$REGISTRY" P1="$PROJ1" P3="$PROJ3" "$PY" - <<'PYEOF'
import json, os
json.dump({
    "11111111-1111-1111-1111-111111111111": os.environ["P1"],
    "33333333-3333-3333-3333-333333333333": os.environ["P3"],
}, open(os.environ["PRESERVE_REG"], "w"), indent=2)
PYEOF

OUT=$(_run_uninstall --confirm)
grep -q "SKIP (symlink)" <<<"$OUT" \
  || fail "symlink safety: expected 'SKIP (symlink)' message. Got:
$OUT"
# Symlink and its target must both survive
[[ -L "$PROJ3/.claude/hash.txt" ]] || fail "symlink safety: symlink hash.txt was deleted"
[[ -f "$SENTINEL" ]]               || fail "symlink safety: symlink target was deleted"
# Regular one still removed
[[ ! -f "$PROJ1/.claude/hash.txt" ]] || fail "symlink run: regular p1 hash.txt should still be deleted"

# --- Assertion 4: no registry → nothing to uninstall ---

rm -f "$REGISTRY"
OUT=$(_run_uninstall)
grep -q "nothing to uninstall" <<<"$OUT" \
  || fail "no-registry: expected 'nothing to uninstall'. Got:
$OUT"

echo "PASS"
