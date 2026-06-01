#!/usr/bin/env bash
# test-search.sh
#
# TDD test for search.sh — keyword search across all session .jsonl under
# ~/.claude/projects, enriched with the registry so each hit shows the
# project's CURRENT path and a ready-to-run resume command.
#
# Assertions:
#   (1) Case-insensitive match on user/assistant text → output names the
#       sessionId, the registered CURRENT path, and a `claude --resume <id>`
#       hint
#   (2) Korean (multibyte) keyword matches — grep -oE broke on this, so the
#       implementation must be parse-based
#   (3) A keyword that appears ONLY in a thinking block is NOT matched
#       (search targets user + assistant text only)
#   (4) A keyword with no hits → a "no matches" message and exit 0

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEARCH_SH="$(cd "$SCRIPT_DIR/.." && pwd)/search.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ ! -f "$SEARCH_SH" ]]; then
  echo "TEST SETUP ERROR: $SEARCH_SH not found" >&2
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

mkdir -p "$FAKE_HOME/.claude/projects"
REGISTRY="$FAKE_HOME/.claude/project-registry.json"

_slug() {
  "$PY" -c "import re,sys,unicodedata,os;print(re.sub(r'[^a-zA-Z0-9-]','-',unicodedata.normalize('NFC',os.path.realpath(sys.argv[1]))))" "$1"
}

_run_search() {
  set +e
  HOME="$FAKE_HOME" bash "$SEARCH_SH" "$@" 2>&1
  set -e
}

# --- Fixtures ---

# Registered project A (English keyword) + project K (Korean keyword).
PROJ_A="$FAKE_HOME/work/projA"; mkdir -p "$PROJ_A"
PROJ_K="$FAKE_HOME/work/projK"; mkdir -p "$PROJ_K"
PROJ_A=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$PROJ_A")
PROJ_K=$("$PY" -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$PROJ_K")

SLUG_A=$(_slug "$PROJ_A")
SLUG_K=$(_slug "$PROJ_K")
mkdir -p "$FAKE_HOME/.claude/projects/$SLUG_A" "$FAKE_HOME/.claude/projects/$SLUG_K"

# Session A — keyword in user + assistant text.
cat > "$FAKE_HOME/.claude/projects/$SLUG_A/sidA.jsonl" <<JSONL
{"type":"user","sessionId":"sidA","cwd":"$PROJ_A","message":{"role":"user","content":"please deploy the ORACLE vm tonight"},"timestamp":"2026-05-01T10:00:00Z"}
{"type":"assistant","sessionId":"sidA","message":{"role":"assistant","content":[{"type":"text","text":"sure, provisioning the instance"}]},"timestamp":"2026-05-01T10:00:05Z"}
JSONL

# Session K — Korean keyword.
cat > "$FAKE_HOME/.claude/projects/$SLUG_K/sidK.jsonl" <<JSONL
{"type":"user","sessionId":"sidK","cwd":"$PROJ_K","message":{"role":"user","content":"오라클 무료 티어 설정 도와줘"},"timestamp":"2026-05-02T10:00:00Z"}
JSONL

# Session T — UNREGISTERED, keyword only inside a thinking block.
SLUG_T="-some-old-unregistered-path"
mkdir -p "$FAKE_HOME/.claude/projects/$SLUG_T"
cat > "$FAKE_HOME/.claude/projects/$SLUG_T/sidT.jsonl" <<JSONL
{"type":"assistant","sessionId":"sidT","message":{"role":"assistant","content":[{"type":"thinking","thinking":"the SECRETTHINKING marker lives only here"}]},"timestamp":"2026-05-03T10:00:00Z"}
JSONL

# Registry maps hashes to the CURRENT paths of A and K (T is unregistered).
PRESERVE_REG="$REGISTRY" PA="$PROJ_A" PK="$PROJ_K" "$PY" - <<'PYEOF'
import json, os
json.dump({"h-a": os.environ["PA"], "h-k": os.environ["PK"]},
          open(os.environ["PRESERVE_REG"], "w"), indent=2)
PYEOF

# --- Assertion 1: case-insensitive English match + registry-aware resume ---

OUT=$(_run_search "oracle")
grep -q "sidA" <<<"$OUT"                       || fail "(1) sidA not in output:\n$OUT"
grep -q "claude --resume sidA" <<<"$OUT"       || fail "(1) missing resume hint for sidA:\n$OUT"
grep -qF "$PROJ_A" <<<"$OUT"                    || fail "(1) registered current path not shown:\n$OUT"

# --- Assertion 2: Korean keyword ---

OUT=$(_run_search "오라클")
grep -q "sidK" <<<"$OUT" \
  || fail "(2) Korean keyword did not match sidK:\n$OUT"

# --- Assertion 3: thinking-only keyword must NOT match ---

OUT=$(_run_search "SECRETTHINKING")
if grep -q "sidT" <<<"$OUT"; then
  fail "(3) thinking-only keyword matched sidT (thinking must be excluded):\n$OUT"
fi

# --- Assertion 4: no matches → message + exit 0 ---

set +e
OUT=$(HOME="$FAKE_HOME" bash "$SEARCH_SH" "zzznomatch12345" 2>&1)
CODE=$?
set -e
[[ $CODE -eq 0 ]] || fail "(4) no-match run should exit 0, got $CODE"
grep -qiE "no .*match|no session" <<<"$OUT" \
  || fail "(4) expected a 'no matches' message:\n$OUT"

echo "PASS"
