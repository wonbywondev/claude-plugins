#!/usr/bin/env bash
# preserve-session: search
# Keyword search across all Claude Code session transcripts under
# ~/.claude/projects, enriched with the registry so each hit shows the
# project's CURRENT path (even after a rename/move) and a ready resume command.
#
# Searches user + assistant message text only (thinking blocks excluded).
# Matching is case-insensitive and multibyte-safe (handles Korean etc.).
#
# Usage:
#   search.sh <keyword>

set -euo pipefail

REGISTRY="$HOME/.claude/project-registry.json"
PROJECTS_DIR="$HOME/.claude/projects"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

KEYWORD="${1:-}"
if [[ -z "$KEYWORD" ]]; then
  echo "Usage: search.sh <keyword>" >&2
  echo "Searches all session transcripts for <keyword> (case-insensitive)." >&2
  exit 1
fi

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "preserve-session search: no sessions directory at $PROJECTS_DIR"
  exit 0
fi

PRESERVE_KEYWORD="$KEYWORD" \
PRESERVE_PROJECTS="$PROJECTS_DIR" \
PRESERVE_REGISTRY="$REGISTRY" \
  "$PYTHON" - <<'PYEOF'
import json, os, re, sys, unicodedata, glob

keyword   = unicodedata.normalize("NFC", os.environ["PRESERVE_KEYWORD"])
projects  = os.environ["PRESERVE_PROJECTS"]
reg_path  = os.environ["PRESERVE_REGISTRY"]
needle    = keyword.casefold()

def slug(p):
    return re.sub(r"[^a-zA-Z0-9-]", "-", unicodedata.normalize("NFC", p))

# Build slug -> current path from the registry (the value-add over plain grep:
# after a rename/move the slug folder name is the OLD path, but the registry
# knows where the project lives now).
slug_to_path = {}
try:
    with open(reg_path) as f:
        reg = json.load(f)
    if isinstance(reg, dict):
        for p in reg.values():
            if isinstance(p, str):
                slug_to_path[slug(p)] = p
except (FileNotFoundError, json.JSONDecodeError, ValueError):
    pass

def texts(obj):
    """Yield user + assistant text from a transcript line (thinking excluded)."""
    msg = obj.get("message", obj)
    if not isinstance(msg, dict):
        return
    role = msg.get("role") or obj.get("type")
    if role not in ("user", "assistant"):
        return
    content = msg.get("content")
    if isinstance(content, str):
        yield content
    elif isinstance(content, list):
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                yield b.get("text", "")

# session file -> {count, last_ts, slug, first_snippet, role}
hits = {}
for path in glob.glob(os.path.join(projects, "**", "*.jsonl"), recursive=True):
    folder_slug = os.path.basename(os.path.dirname(path))
    session_id  = os.path.basename(path)[:-len(".jsonl")]
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if not line.strip():
                    continue
                # cheap pre-filter before JSON parse
                if needle not in line.casefold():
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                ts = obj.get("timestamp", "")
                for t in texts(obj):
                    tn = unicodedata.normalize("NFC", t)
                    idx = tn.casefold().find(needle)
                    if idx < 0:
                        continue
                    h = hits.setdefault(path, {
                        "count": 0, "last_ts": "", "slug": folder_slug,
                        "session_id": session_id, "snippet": "", "role": "",
                    })
                    h["count"] += 1
                    if ts > h["last_ts"]:
                        h["last_ts"] = ts
                    if not h["snippet"]:
                        s = max(0, idx - 60)
                        h["snippet"] = tn[s:idx + len(keyword) + 90].replace("\n", " ").strip()
                        h["role"] = msg_role = (obj.get("message", {}) or {}).get("role") or obj.get("type", "")
                    break  # one snippet per line is enough
    except (OSError, IOError):
        continue

if not hits:
    print(f'preserve-session search: no sessions matching "{keyword}"')
    sys.exit(0)

# Most recently active sessions first.
ordered = sorted(hits.items(), key=lambda kv: kv[1]["last_ts"], reverse=True)

print(f'preserve-session search: "{keyword}"')
print("=" * (28 + len(keyword)))
print()

for path, h in ordered:
    cur = slug_to_path.get(h["slug"])
    date = h["last_ts"][:10] or "?"
    header_path = cur if cur else f'{h["slug"]}  (unregistered)'
    print(f'{header_path}   ({h["count"]} match(es), last {date})')
    if cur:
        print(f'  resume: cd "{cur}" && claude --resume {h["session_id"]}')
    else:
        print(f'  resume: claude --resume {h["session_id"]}   (path unknown — not in registry)')
    if h["snippet"]:
        print(f'  [{h["role"]}] …{h["snippet"]}…')
    print()

print(f'{len(ordered)} session(s) matched.')
PYEOF
