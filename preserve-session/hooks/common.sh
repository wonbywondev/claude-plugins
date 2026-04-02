#!/usr/bin/env bash
# preserve-session: shared helpers
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

find_python() {
  for candidate in python3 python /usr/bin/python3 /usr/local/bin/python3; do
    if command -v "$candidate" >/dev/null 2>&1 && \
       "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= (3,6) else 1)" 2>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done
  echo "preserve-session: no usable python3 found" >&2
  exit 1
}

PYTHON=$(find_python)

path_to_slug() {
  local resolved
  resolved=$(realpath "$1" 2>/dev/null || echo "$1")
  "$PYTHON" -c "import re, sys, unicodedata; print(re.sub(r'[^a-zA-Z0-9-]', '-', unicodedata.normalize('NFC', sys.argv[1])))" "$resolved"
}

uuidgen_cross() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    cat /proc/sys/kernel/random/uuid 2>/dev/null || "$PYTHON" -c "import uuid; print(uuid.uuid4())"
  fi
}

# check_slug_collision <path>
# Prints registered paths that share the same slug as <path> (excluding <path> itself).
# Empty output means no collision.
check_slug_collision() {
  PRESERVE_CHECK_PATH="$1" "$PYTHON" - <<'PYEOF'
import json, os, re, unicodedata, sys

registry_path = os.path.expanduser("~/.claude/project-registry.json")
check_path = os.environ["PRESERVE_CHECK_PATH"]

try:
    with open(registry_path) as f:
        r = json.load(f)
except (FileNotFoundError, json.JSONDecodeError, ValueError):
    sys.exit(0)

def slug(p):
    return re.sub(r'[^a-zA-Z0-9-]', '-', unicodedata.normalize('NFC', p))

check_slug = slug(check_path)
for h, p in r.items():
    if p == check_path:
        continue
    if slug(p) == check_slug:
        print(p)
PYEOF
}
