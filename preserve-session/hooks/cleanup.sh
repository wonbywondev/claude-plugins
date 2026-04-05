#!/usr/bin/env bash
# preserve-session: cleanup
# Usage:
#   cleanup.sh                     List all registered projects with status
#   cleanup.sh --remove <p1> ...   Remove specified paths from registry

set -euo pipefail

REGISTRY="$HOME/.claude/project-registry.json"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

MODE="${1:-}"

# --- List mode (default) ---

if [[ -z "$MODE" ]]; then
  if [[ ! -f "$REGISTRY" ]]; then
    echo "preserve-session: registry not found — nothing to clean up."
    exit 0
  fi

  PRESERVE_REGISTRY="$REGISTRY" "$PYTHON" - <<'PYEOF'
import json, os, sys

registry_path = os.environ["PRESERVE_REGISTRY"]
try:
    with open(registry_path) as f:
        r = json.load(f)
except FileNotFoundError:
    print("preserve-session: registry not found — nothing to clean up.")
    sys.exit(0)
except (json.JSONDecodeError, ValueError):
    print("preserve-session: registry is corrupted. Fix or delete ~/.claude/project-registry.json and retry.", file=sys.stderr)
    sys.exit(1)

if not isinstance(r, dict):
    print("preserve-session: registry has unexpected format (not a JSON object).", file=sys.stderr)
    sys.exit(1)

if not r:
    print("preserve-session: registry is empty — nothing to clean up.")
    sys.exit(0)

entries = []
stale_count = 0
for h, p in r.items():
    if not isinstance(p, str):
        continue
    exists = os.path.isdir(p)
    if not exists:
        stale_count += 1
    entries.append((h, p, exists))

total = len(entries)
print(f"Registered projects ({total} total, {stale_count} stale):")
print("")
for i, (h, p, exists) in enumerate(entries, 1):
    status = "\u2713" if exists else "\u2717"
    note = "  \u2190 path not found" if not exists else ""
    print(f"  {i:3}. {status}  {p}  [{h[:8]}]{note}")
print("")
if stale_count > 0:
    stale_part = f", 'stale' (remove {stale_count} stale)"
else:
    stale_part = ""
print(f"Select entries to remove: numbers (e.g. 1 3){stale_part}, or 'all' (remove all {total}).")
PYEOF
  exit 0
fi

# --- Remove mode ---

if [[ "$MODE" != "--remove" ]]; then
  echo "preserve-session: unrecognized argument '$MODE'. Usage: cleanup.sh [--remove <path> ...]" >&2
  exit 1
fi

shift  # remove --remove
if [[ $# -eq 0 ]]; then
  echo "Usage: cleanup.sh --remove <path1> [path2 ...]" >&2
  exit 1
fi

# Pass paths as newline-separated env var (paths in registry are guaranteed newline-free)
PRESERVE_REMOVE=$(printf '%s\n' "$@") \
PRESERVE_REGISTRY="$REGISTRY" \
  "$PYTHON" - <<'PYEOF'
import fcntl, json, os, sys, tempfile

registry_path = os.environ["PRESERVE_REGISTRY"]
paths_to_remove = set(p for p in os.environ["PRESERVE_REMOVE"].splitlines() if p)

lock_path = registry_path + ".lock"
with open(lock_path, "a") as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    try:
        with open(registry_path) as f:
            r = json.load(f)
    except FileNotFoundError:
        print("preserve-session: registry not found.", file=sys.stderr)
        sys.exit(1)
    except (json.JSONDecodeError, ValueError):
        print("preserve-session: registry is corrupted.", file=sys.stderr)
        sys.exit(1)

    if not isinstance(r, dict):
        print("preserve-session: registry has unexpected format.", file=sys.stderr)
        sys.exit(1)

    registered_paths = {p for p in r.values() if isinstance(p, str)}
    not_found = [p for p in paths_to_remove if p not in registered_paths]

    new_r = {h: p for h, p in r.items() if p not in paths_to_remove}
    removed_count = len(r) - len(new_r)

    print(f"Removing {removed_count} entry(entries) from registry...")
    print("")
    for h, p in r.items():
        if p in paths_to_remove:
            print(f"  removed: {p}")
    for p in not_found:
        print(f"  WARNING: not found in registry: {p}")

    tmp_fd, tmp_path = tempfile.mkstemp(
        dir=os.path.dirname(registry_path), suffix=".tmp"
    )
    try:
        with os.fdopen(tmp_fd, "w") as f:
            json.dump(new_r, f, indent=2)
        os.replace(tmp_path, registry_path)
    except OSError as e:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        print(f"preserve-session: failed to write registry: {e}", file=sys.stderr)
        sys.exit(1)

print("")
kept = len(new_r)
print(f"Done. {removed_count} entry(entries) removed. {kept} entry(entries) kept.")
if not_found:
    print(f"  {len(not_found)} path(s) not found in registry.")
PYEOF
