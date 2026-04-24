#!/usr/bin/env bash
# community-tracker.sh
#
# Tracks anthropics/claude-plugins-community marketplace.json for the
# preserve-session plugin's pinned SHA. Each run:
#   1. Extracts current pinned SHA from community marketplace.json
#   2. Resolves SHA → version by reading plugin.json at that SHA
#   3. Writes a shields.io endpoint JSON so README badges stay in sync
#   4. On SHA change since last notification, sends one ntfy push
#
# This workflow is persistent (every 15 min), no self-disable — the badge
# needs to keep updating whenever Anthropic refreshes the pin.

set -euo pipefail

# Resolve repo root from .github/scripts/ (two levels up)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$ROOT_DIR/.github/state"
SHA_STATE_FILE="$STATE_DIR/preserve-session-sha.json"
BADGE_STATE_FILE="$STATE_DIR/preserve-session-community-version.json"
mkdir -p "$STATE_DIR"

COMMUNITY_REPO="anthropics/claude-plugins-community"
PLUGIN_NAME="preserve-session"
PLUGIN_SRC_REPO="wonbywondev/claude-plugins"
PLUGIN_SUBPATH="plugins/preserve-session/.claude-plugin/plugin.json"
COMMUNITY_URL="https://raw.githubusercontent.com/$COMMUNITY_REPO/main/.claude-plugin/marketplace.json"

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Read prior state -------------------------------------------------------
OLD_SHA=""
OLD_LAST_NOTIFIED=""
if [[ -f "$SHA_STATE_FILE" ]]; then
  OLD_SHA=$(python3 -c "import json; print(json.load(open('$SHA_STATE_FILE')).get('sha','') or '')" 2>/dev/null || echo "")
  OLD_LAST_NOTIFIED=$(python3 -c "import json; print(json.load(open('$SHA_STATE_FILE')).get('last_notified_sha','') or '')" 2>/dev/null || echo "")
fi

# --- Fetch current pinned SHA from community marketplace --------------------
CURRENT_SHA=$(curl -sf "$COMMUNITY_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for p in d.get('plugins', []):
    if p.get('name') == '$PLUGIN_NAME':
        src = p.get('source', {}) or {}
        if isinstance(src, dict):
            print(src.get('sha', '') or '')
        break
" || true)
CURRENT_SHA="${CURRENT_SHA:-}"

# Network / parse failure: preserve prior state, just bump checked_at
if [[ -z "$CURRENT_SHA" ]]; then
  echo "WARNING: failed to extract SHA from community marketplace.json — preserving prior state"
  if [[ -f "$SHA_STATE_FILE" ]]; then
    python3 - "$SHA_STATE_FILE" "$NOW" <<'PYEOF'
import json, sys
path, now = sys.argv[1], sys.argv[2]
with open(path) as f:
    d = json.load(f)
d["checked_at"] = now
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF
  fi
  exit 0
fi

# --- Resolve SHA → version by fetching plugin.json at that SHA --------------
PLUGIN_JSON_URL="https://raw.githubusercontent.com/$PLUGIN_SRC_REPO/$CURRENT_SHA/$PLUGIN_SUBPATH"
CURRENT_VERSION=$(curl -sf "$PLUGIN_JSON_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get('version', '') or '')
" || true)
CURRENT_VERSION="${CURRENT_VERSION:-}"

# --- Write shields.io endpoint JSON -----------------------------------------
if [[ -n "$CURRENT_VERSION" ]]; then
  BADGE_MSG="v$CURRENT_VERSION"
  BADGE_COLOR="green"
else
  BADGE_MSG="unknown"
  BADGE_COLOR="lightgrey"
  echo "WARNING: could not resolve version from plugin.json at SHA $CURRENT_SHA"
fi

python3 - "$BADGE_STATE_FILE" "$BADGE_MSG" "$BADGE_COLOR" <<'PYEOF'
import json, sys
path, msg, color = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "w") as f:
    json.dump({
        "schemaVersion": 1,
        "label": "community",
        "message": msg,
        "color": color,
    }, f, indent=2)
    f.write("\n")
PYEOF

# --- Determine notify action ------------------------------------------------
# Treat "missing last_notified_sha" as bootstrap/migration — set to CURRENT
# so we don't ntfy on the first run after upgrading the schema.
if [[ -z "$OLD_LAST_NOTIFIED" ]]; then
  NEW_LAST_NOTIFIED="$CURRENT_SHA"
  IS_BOOTSTRAP=1
else
  NEW_LAST_NOTIFIED="$OLD_LAST_NOTIFIED"
  IS_BOOTSTRAP=0
fi

# --- Write SHA state --------------------------------------------------------
python3 - "$SHA_STATE_FILE" "$CURRENT_SHA" "$OLD_SHA" "$NEW_LAST_NOTIFIED" "$NOW" <<'PYEOF'
import json, sys
path, sha, prev, last_notified, now = sys.argv[1:6]
with open(path, "w") as f:
    json.dump({
        "sha": sha,
        "previous": prev,
        "last_notified_sha": last_notified,
        "checked_at": now,
    }, f, indent=2)
    f.write("\n")
PYEOF

# --- Bootstrap / migration: done, no notify --------------------------------
if [[ "$IS_BOOTSTRAP" == "1" ]]; then
  echo "bootstrap/migration: sha=$CURRENT_SHA version=$CURRENT_VERSION"
  exit 0
fi

# --- No new SHA since last notification → quiet -----------------------------
if [[ "$CURRENT_SHA" == "$NEW_LAST_NOTIFIED" ]]; then
  echo "no change vs last notification (sha=$CURRENT_SHA, version=$CURRENT_VERSION)"
  exit 0
fi

# --- SHA moved → one ntfy push ---------------------------------------------
echo "SHA moved since last notification: $NEW_LAST_NOTIFIED -> $CURRENT_SHA"
if [[ -n "${NTFY_TOPIC:-}" ]]; then
  SHORT_OLD="${NEW_LAST_NOTIFIED:0:7}"
  SHORT_NEW="${CURRENT_SHA:0:7}"
  if curl -s \
      -H "Title: 🔄 preserve-session pin refreshed" \
      -H "Tags: arrows_counterclockwise,rocket" \
      -H "Priority: high" \
      -H "Click: https://github.com/$COMMUNITY_REPO/blob/main/.claude-plugin/marketplace.json" \
      -d "Community pin: $SHORT_OLD → $SHORT_NEW (v${CURRENT_VERSION:-?}). CLI users will now receive the newer plugin version." \
      "https://ntfy.sh/$NTFY_TOPIC" > /dev/null; then
    echo "ntfy sent"
    python3 - "$SHA_STATE_FILE" "$CURRENT_SHA" <<'PYEOF'
import json, sys
path, sha = sys.argv[1], sys.argv[2]
with open(path) as f:
    d = json.load(f)
d["last_notified_sha"] = sha
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF
  else
    echo "WARNING: ntfy curl failed — will retry next run"
  fi
else
  echo "SHA changed but NTFY_TOPIC not set"
fi
