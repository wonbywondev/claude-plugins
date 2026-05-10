#!/usr/bin/env bash
# fetch-new-releases.sh
#
# Maintains .github/state/claude-code-releases.json — a single index of recent
# Anthropic Claude Code releases. Each run:
#   1. Fetches the latest N releases from anthropics/claude-code via the
#      GitHub REST API (curl). Avoids `gh` CLI because the workflow's
#      GITHUB_TOKEN sometimes returns 0 results for cross-repo `gh release
#      list` queries.
#   2. For each release not already in the index, fetches body + runs keyword
#      regex.
#   3. Prepends new entries to the index (sorted newest-first).
#
# Auth: uses GH_TOKEN/GITHUB_TOKEN if present (5000 req/h), else anonymous
# (60 req/h per IP — fine for one-off runs).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX_FILE="$ROOT_DIR/.github/state/claude-code-releases.json"
mkdir -p "$(dirname "$INDEX_FILE")"

UPSTREAM_REPO="anthropics/claude-code"
LIMIT="${FETCH_LIMIT:-30}"
SOURCE_URL="https://github.com/$UPSTREAM_REPO/releases"

KEYWORDS='session|sessionId|cwd|parentUuid|hook|SessionStart|PostToolUse|slug|path encoding|NFC|NFD|[-/]resume|cleanupPeriodDays|projects directory|plugin|plugin\.json|marketplace\.json|hooks\.json|path-independent|hash\.txt|~/\.claude/projects'

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Auth header ------------------------------------------------------------
AUTH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
api_get() {
  local url="$1"
  if [[ -n "$AUTH_TOKEN" ]]; then
    curl -sf -H "Authorization: Bearer $AUTH_TOKEN" -H "Accept: application/vnd.github+json" "$url"
  else
    curl -sf -H "Accept: application/vnd.github+json" "$url"
  fi
}

# --- Fetch release list -----------------------------------------------------
LIST_URL="https://api.github.com/repos/$UPSTREAM_REPO/releases?per_page=$LIMIT"
RELEASES_JSON=$(api_get "$LIST_URL" || echo "[]")

RELEASE_LINES=$(echo "$RELEASES_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(data, list):
    sys.exit(0)
for r in data:
    if r.get('draft') or r.get('prerelease'):
        continue
    print(f\"{r.get('published_at','')}|{r.get('tag_name','')}\")
")

if [[ -z "$RELEASE_LINES" ]]; then
  echo "WARNING: failed to fetch release list — preserving prior state"
  if [[ -f "$INDEX_FILE" ]]; then
    python3 - "$INDEX_FILE" "$NOW" "$SOURCE_URL" <<'PYEOF'
import json, sys
path, now, source = sys.argv[1:4]
with open(path) as f:
    d = json.load(f)
d["last_updated"] = now
d.setdefault("source", source)
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF
  fi
  exit 0
fi

# --- Load existing index ----------------------------------------------------
if [[ -f "$INDEX_FILE" ]]; then
  EXISTING_JSON=$(cat "$INDEX_FILE")
else
  EXISTING_JSON='{"releases":[]}'
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

new_count=0

while IFS='|' read -r PUBLISHED TAG; do
  [[ -z "$TAG" ]] && continue
  DATE="${PUBLISHED:0:10}"

  ALREADY=$(echo "$EXISTING_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
tag = '$TAG'
for r in d.get('releases', []):
    if r.get('tag') == tag:
        print('yes')
        break
")
  if [[ "$ALREADY" == "yes" ]]; then
    continue
  fi

  BODY_URL="https://api.github.com/repos/$UPSTREAM_REPO/releases/tags/$TAG"
  BODY_JSON=$(api_get "$BODY_URL" || echo "{}")
  BODY=$(echo "$BODY_JSON" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('body', '') or '')
except Exception:
    pass
")
  URL="https://github.com/$UPSTREAM_REPO/releases/tag/$TAG"

  MATCHES=$(echo "$BODY" | grep -iE "$KEYWORDS" 2>/dev/null || true)
  if [[ -z "$MATCHES" ]]; then
    HITS=0
  else
    HITS=$(printf "%s\n" "$MATCHES" | wc -l | tr -d ' ')
  fi

  python3 - "$TMPFILE" "$TAG" "$DATE" "$URL" "$HITS" <<'PYEOF'
import json, sys
path, tag, date, url, hits = sys.argv[1:6]
with open(path, "a") as f:
    f.write(json.dumps({"tag": tag, "published": date, "url": url, "keyword_hits": int(hits)}) + "\n")
PYEOF

  echo "new: $TAG ($DATE, hits=$HITS)"
  new_count=$((new_count + 1))
done <<< "$RELEASE_LINES"

echo ""
echo "fetch-new-releases: $new_count new entrie(s)"

if [[ "$new_count" -eq 0 ]]; then
  python3 - "$INDEX_FILE" "$NOW" "$SOURCE_URL" <<'PYEOF'
import json, sys
path, now, source = sys.argv[1:4]
with open(path) as f:
    d = json.load(f)
d["last_updated"] = now
d.setdefault("source", source)
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF
  exit 0
fi

# Merge new entries into index
python3 - "$INDEX_FILE" "$TMPFILE" "$NOW" "$SOURCE_URL" <<'PYEOF'
import json, sys
index_path, new_path, now, source = sys.argv[1:5]
try:
    with open(index_path) as f:
        d = json.load(f)
except Exception:
    d = {"releases": []}
releases = d.get("releases", [])
with open(new_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        releases.append(json.loads(line))
seen = set()
deduped = []
for r in releases:
    t = r.get("tag")
    if t in seen:
        continue
    seen.add(t)
    deduped.append(r)
deduped.sort(key=lambda r: (r.get("published", ""), r.get("tag", "")), reverse=True)
d["releases"] = deduped
d["last_updated"] = now
d.setdefault("source", source)
with open(index_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF

echo "index updated: $INDEX_FILE"
