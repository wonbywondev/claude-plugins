#!/usr/bin/env bash
# e2e-smoke.sh — REAL end-to-end smoke test using the actual `claude` binary.
#
# This is the link the hermetic test-*.sh suite cannot prove: that after a
# project is renamed and fix.sh migrates the slug folder, `claude --continue`
# ACTUALLY resumes the prior conversation. It exercises the real binary, the
# repo's own session-start.sh + fix.sh, and the real resume path.
#
# NOT hermetic and NOT run by run-all.sh (the filename does not match
# test-*.sh). Opt-in / manual only, because it:
#   - launches `claude -p` twice (needs auth + network, burns a few tokens)
#   - creates real session transcripts under ~/.claude/projects/
#   - temporarily mutates ~/.claude/project-registry.json
# It backs up the registry and removes everything it created on exit (even on
# failure, via an EXIT trap).
#
# Important: SessionStart hooks do NOT fire in headless `claude -p`, so this
# script runs session-start.sh directly to register the project — the same
# script the interactive hook runs.
#
# Usage:
#   bash e2e-smoke.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SS_SH="$HOOKS_DIR/session-start.sh"
FIX_SH="$HOOKS_DIR/fix.sh"
REGISTRY="$HOME/.claude/project-registry.json"

fail() { echo "FAIL: $*" >&2; exit 1; }
skip() { echo "SKIP: $*" >&2; exit 0; }

_pick_python() {
  for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1; then echo "$c"; return 0; fi
  done
  echo "TEST SETUP ERROR: no python available" >&2; exit 2
}
PY=$(_pick_python)

command -v claude >/dev/null 2>&1 || skip "claude binary not found on PATH — e2e cannot run"
[[ -f "$SS_SH"  ]] || fail "session-start.sh not found at $SS_SH"
[[ -f "$FIX_SH" ]] || fail "fix.sh not found at $FIX_SH"

_slug() {
  "$PY" -c "import re,sys,unicodedata,os; print(re.sub(r'[^a-zA-Z0-9-]','-',unicodedata.normalize('NFC',os.path.realpath(sys.argv[1]))))" "$1"
}

# --- Cleanup state (populated as we go; the trap tears everything down) ---

WORKSPACE=""
REG_BACKUP=""
SLUG_A=""
SLUG_B=""

_cleanup() {
  # Restore the registry exactly as it was.
  if [[ -n "$REG_BACKUP" && -f "$REG_BACKUP" ]]; then
    cp "$REG_BACKUP" "$REGISTRY" 2>/dev/null || true
    rm -f "$REG_BACKUP"
  fi
  # Remove the slug folders this run created.
  [[ -n "$SLUG_A" ]] && rm -rf "$HOME/.claude/projects/$SLUG_A" 2>/dev/null || true
  [[ -n "$SLUG_B" ]] && rm -rf "$HOME/.claude/projects/$SLUG_B" 2>/dev/null || true
  # Remove the temp workspace.
  [[ -n "$WORKSPACE" ]] && rm -rf "$WORKSPACE" 2>/dev/null || true
}
trap _cleanup EXIT

# --- Back up the real registry ---

if [[ -f "$REGISTRY" ]]; then
  REG_BACKUP=$(mktemp)
  cp "$REGISTRY" "$REG_BACKUP"
fi

# --- Workspace + unique codeword ---

WORKSPACE=$(mktemp -d)
PROJ_A="$WORKSPACE/projA"
mkdir -p "$PROJ_A"
PROJ_A=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$PROJ_A")
# Unique token so the recall can't be satisfied from the model's priors.
CODEWORD="ZUCCHINI-${RANDOM}${RANDOM}"

echo "e2e-smoke: workspace=$WORKSPACE"
echo "e2e-smoke: codeword=$CODEWORD"

# --- Step 1: create a real session in project A ---

echo "[1/5] creating session in projA via 'claude -p' ..."
OUT1=$(cd "$PROJ_A" && claude -p "Remember this codeword for later: $CODEWORD. Reply with exactly: STORED" < /dev/null 2>&1)
RC1=$?
if [[ $RC1 -ne 0 ]]; then
  skip "claude -p failed (rc=$RC1) — likely auth/network. Output:
$OUT1"
fi

SLUG_A=$(_slug "$PROJ_A")
shopt -s nullglob
A_FILES=("$HOME/.claude/projects/$SLUG_A"/*.jsonl)
shopt -u nullglob
[[ ${#A_FILES[@]} -ge 1 ]] \
  || fail "no session .jsonl created in projA slug folder ($HOME/.claude/projects/$SLUG_A)"

# --- Step 2: register projA via the real session-start.sh (hook doesn't fire in -p) ---

echo "[2/5] registering projA via session-start.sh ..."
(cd "$PROJ_A" && HOME="$HOME" bash "$SS_SH") || fail "session-start.sh failed in projA"

HASH=$(cat "$PROJ_A/.claude/hash.txt" 2>/dev/null)
[[ -n "$HASH" ]] || fail "session-start.sh did not write hash.txt in projA"

REG_A=$(PRESERVE_REG="$REGISTRY" PRESERVE_H="$HASH" "$PY" -c "import json,os;print(json.load(open(os.environ['PRESERVE_REG'])).get(os.environ['PRESERVE_H'],''))")
[[ "$REG_A" == "$PROJ_A" ]] \
  || fail "projA not registered correctly: registry[$HASH]='$REG_A', expected '$PROJ_A'"

# --- Step 3: rename projA -> projB (hash.txt + .claude travel with it) ---

echo "[3/5] renaming projA -> projB ..."
PROJ_B="$WORKSPACE/projB"
mv "$PROJ_A" "$PROJ_B" || fail "mv projA -> projB failed"
PROJ_B=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$PROJ_B")
SLUG_B=$(_slug "$PROJ_B")

# --- Step 4: fix.sh migrates the slug folder and updates the registry ---

echo "[4/5] running fix.sh in projB ..."
OUT4=$(cd "$PROJ_B" && HOME="$HOME" bash "$FIX_SH" 2>&1)
RC4=$?
[[ $RC4 -eq 0 ]] || fail "fix.sh failed (rc=$RC4). Output:
$OUT4"
grep -q "detected rename/move" <<<"$OUT4" \
  || fail "fix.sh did not report a rename/move. Output:
$OUT4"

[[ -d "$HOME/.claude/projects/$SLUG_B" ]] \
  || fail "fix.sh did not create the new slug folder $HOME/.claude/projects/$SLUG_B"

REG_B=$(PRESERVE_REG="$REGISTRY" PRESERVE_H="$HASH" "$PY" -c "import json,os;print(json.load(open(os.environ['PRESERVE_REG'])).get(os.environ['PRESERVE_H'],''))")
[[ "$REG_B" == "$PROJ_B" ]] \
  || fail "fix.sh did not update registry to projB: registry[$HASH]='$REG_B', expected '$PROJ_B'"

# --- Step 5: the payoff — `claude --continue` resumes the migrated session ---

echo "[5/5] resuming with 'claude -p --continue' in projB ..."
OUT5=$(cd "$PROJ_B" && claude -p --continue "What codeword did I ask you to remember? Reply with only the codeword." < /dev/null 2>&1)
RC5=$?
[[ $RC5 -eq 0 ]] || fail "claude --continue failed (rc=$RC5). Output:
$OUT5"

grep -qF "$CODEWORD" <<<"$OUT5" \
  || fail "resumed session did NOT recall the codeword '$CODEWORD' after rename+fix.
This means session history did not survive the migration end-to-end.
claude --continue output:
$OUT5"

echo "PASS — codeword survived rename+fix and was recalled via claude --continue"
