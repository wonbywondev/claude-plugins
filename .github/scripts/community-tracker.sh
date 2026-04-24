#!/usr/bin/env bash
# community-tracker.sh
#
# Tracks every plugin hosted in this repo that is listed in
# anthropics/claude-plugins-community marketplace. For each such plugin:
#   1. Extracts the pinned SHA from community marketplace.json
#   2. Resolves SHA → version by reading plugin.json at that SHA
#   3. Writes a shields.io endpoint JSON for the README badge
#   4. On SHA change since last notification, sends one ntfy push
#
# Workflow is persistent (every 15 min). No self-disable — badges need to
# update whenever Anthropic refreshes any pin.

set -euo pipefail

# Resolve repo root from .github/scripts/ (two levels up)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$ROOT_DIR/.github/state"
mkdir -p "$STATE_DIR"

COMMUNITY_REPO="anthropics/claude-plugins-community"
SOURCE_REPO_URL_PATTERN="wonbywondev/claude-plugins"  # match plugins hosted here
COMMUNITY_URL="https://raw.githubusercontent.com/$COMMUNITY_REPO/main/.claude-plugin/marketplace.json"

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Fetch community marketplace once
MARKETPLACE_JSON=$(curl -sf "$COMMUNITY_URL" 2>/dev/null || true)
if [[ -z "$MARKETPLACE_JSON" ]]; then
  echo "WARNING: failed to fetch community marketplace — preserving prior state"
  exit 0
fi

# Extract plugins whose source URL belongs to this repo, as "name<TAB>sha" pairs
PLUGINS_TO_TRACK=$(echo "$MARKETPLACE_JSON" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
pattern = '$SOURCE_REPO_URL_PATTERN'
for p in d.get('plugins', []):
    name = p.get('name', '')
    src = p.get('source', {}) or {}
    if not isinstance(src, dict):
        continue
    src_url = src.get('url') or ''
    if src.get('source') == 'url' and pattern in src_url:
        sha = src.get('sha', '') or ''
        if name and sha:
            print(f'{name}\t{sha}')
")

if [[ -z "$PLUGINS_TO_TRACK" ]]; then
  echo "no plugins from $SOURCE_REPO_URL_PATTERN found in community marketplace"
  exit 0
fi

# Process each tracked plugin
while IFS=$'\t' read -r PLUGIN_NAME CURRENT_SHA; do
  [[ -z "$PLUGIN_NAME" ]] && continue
  echo "=== $PLUGIN_NAME (SHA $CURRENT_SHA) ==="

  SHA_STATE_FILE="$STATE_DIR/$PLUGIN_NAME-sha.json"
  BADGE_STATE_FILE="$STATE_DIR/$PLUGIN_NAME-community-version.json"

  # Read prior state
  OLD_SHA=""
  OLD_LAST_NOTIFIED=""
  if [[ -f "$SHA_STATE_FILE" ]]; then
    OLD_SHA=$(python3 -c "import json; print(json.load(open('$SHA_STATE_FILE')).get('sha','') or '')" 2>/dev/null || echo "")
    OLD_LAST_NOTIFIED=$(python3 -c "import json; print(json.load(open('$SHA_STATE_FILE')).get('last_notified_sha','') or '')" 2>/dev/null || echo "")
  fi

  # Resolve SHA → version by fetching plugin.json at that SHA
  PLUGIN_JSON_URL="https://raw.githubusercontent.com/$SOURCE_REPO_URL_PATTERN/$CURRENT_SHA/plugins/$PLUGIN_NAME/.claude-plugin/plugin.json"
  CURRENT_VERSION=$(curl -sf "$PLUGIN_JSON_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get('version', '') or '')
" || true)
  CURRENT_VERSION="${CURRENT_VERSION:-}"

  # Write shields.io badge JSON
  if [[ -n "$CURRENT_VERSION" ]]; then
    BADGE_MSG="v$CURRENT_VERSION"
    BADGE_COLOR="green"
  else
    BADGE_MSG="unknown"
    BADGE_COLOR="lightgrey"
    echo "  WARNING: could not resolve version from plugin.json"
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

  # Determine notify action
  if [[ -z "$OLD_LAST_NOTIFIED" ]]; then
    NEW_LAST_NOTIFIED="$CURRENT_SHA"
    IS_BOOTSTRAP=1
  else
    NEW_LAST_NOTIFIED="$OLD_LAST_NOTIFIED"
    IS_BOOTSTRAP=0
  fi

  # Write SHA state
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

  if [[ "$IS_BOOTSTRAP" == "1" ]]; then
    echo "  bootstrap/migration: sha=$CURRENT_SHA version=$CURRENT_VERSION"
    continue
  fi

  if [[ "$CURRENT_SHA" == "$NEW_LAST_NOTIFIED" ]]; then
    echo "  no change vs last notification"
    continue
  fi

  # SHA moved → ntfy push (per-plugin)
  echo "  SHA moved: $NEW_LAST_NOTIFIED -> $CURRENT_SHA"
  if [[ -n "${NTFY_TOPIC:-}" ]]; then
    SHORT_OLD="${NEW_LAST_NOTIFIED:0:7}"
    SHORT_NEW="${CURRENT_SHA:0:7}"
    if curl -s \
        -H "Title: 🔄 $PLUGIN_NAME pin refreshed" \
        -H "Tags: arrows_counterclockwise,rocket" \
        -H "Priority: high" \
        -H "Click: https://github.com/$COMMUNITY_REPO/blob/main/.claude-plugin/marketplace.json" \
        -d "Community pin ($PLUGIN_NAME): $SHORT_OLD → $SHORT_NEW (v${CURRENT_VERSION:-?}). CLI users will now receive the newer plugin version." \
        "https://ntfy.sh/$NTFY_TOPIC" > /dev/null; then
      echo "  ntfy sent"
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
      echo "  WARNING: ntfy curl failed — will retry next run"
    fi
  else
    echo "  SHA changed but NTFY_TOPIC not set"
  fi
done <<< "$PLUGINS_TO_TRACK"
