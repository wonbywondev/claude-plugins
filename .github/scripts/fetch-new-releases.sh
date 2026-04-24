#!/usr/bin/env bash
# fetch-new-releases.sh
#
# Maintains .github/state/claude-code-releases.json — a single index of recent
# Anthropic Claude Code releases. On each run:
#   1. Fetches the latest N releases from anthropics/claude-code via gh CLI
#   2. For each release not already in the index, fetches body + runs keyword regex
#   3. Prepends new entries to the index (sorted newest-first)
#
# Downstream consumers (each plugin's upstream-check hook) read this JSON to
# compare plugin_ack against latest tag and surface triage gaps.
#
# Environment:
#   GH_TOKEN / GITHUB_TOKEN must be set for `gh` CLI in CI contexts.

set -euo pipefail

# Resolve repo root from .github/scripts/ (two levels up)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX_FILE="$ROOT_DIR/.github/state/claude-code-releases.json"
mkdir -p "$(dirname "$INDEX_FILE")"

UPSTREAM_REPO="anthropics/claude-code"
LIMIT="${FETCH_LIMIT:-30}"
SOURCE_URL="https://github.com/$UPSTREAM_REPO/releases"

KEYWORDS='session|sessionId|cwd|parentUuid|hook|SessionStart|PostToolUse|slug|path encoding|NFC|NFD|[-/]resume|cleanupPeriodDays|projects directory|plugin|plugin\.json|marketplace\.json|hooks\.json|path-independent|hash\.txt|~/\.claude/projects'

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Load existing index (or bootstrap empty)
if [[ -f "$INDEX_FILE" ]]; then
  EXISTING_JSON=$(cat "$INDEX_FILE")
else
  EXISTING_JSON='{"releases":[]}'
fi

# Collect new releases
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

new_count=0

while IFS='|' read -r PUBLISHED TAG; do
  DATE="${PUBLISHED:0:10}"

  # Skip if this tag is already in the index
  ALREADY=$(echo "$EXISTING_JSON" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
tag = '$TAG'
for r in d.get('releases', []):
    if r.get('tag') == tag:
        print('yes')
        break
")
  if [[ "$ALREADY" == "yes" ]]; then
    continue
  fi

  BODY=$(gh release view "$TAG" --repo "$UPSTREAM_REPO" --json body --jq '.body' 2>/dev/null || echo "")
  URL="https://github.com/$UPSTREAM_REPO/releases/tag/$TAG"

  MATCHES=$(echo "$BODY" | grep -iE "$KEYWORDS" 2>/dev/null || true)
  if [[ -z "$MATCHES" ]]; then
    HITS=0
  else
    HITS=$(printf "%s\n" "$MATCHES" | wc -l | tr -d ' ')
  fi

  # Append the entry (tag, published, url, keyword_hits) as JSON line
  python3 - "$TMPFILE" "$TAG" "$DATE" "$URL" "$HITS" <<'PYEOF'
import json, sys
path, tag, date, url, hits = sys.argv[1:6]
with open(path, "a") as f:
    f.write(json.dumps({"tag": tag, "published": date, "url": url, "keyword_hits": int(hits)}) + "\n")
PYEOF

  echo "new: $TAG ($DATE, hits=$HITS)"
  new_count=$((new_count + 1))
done < <(gh release list --repo "$UPSTREAM_REPO" --limit "$LIMIT" \
          --json tagName,publishedAt \
          --jq '.[] | "\(.publishedAt)|\(.tagName)"')

echo ""
echo "fetch-new-releases: $new_count new entrie(s)"

if [[ "$new_count" -eq 0 ]]; then
  # Still bump last_updated
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

# Merge new entries into index and re-sort
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
# dedupe by tag (newest entry wins if any dupes)
seen = set()
deduped = []
for r in releases:
    t = r.get("tag")
    if t in seen:
        continue
    seen.add(t)
    deduped.append(r)
# sort newest first
deduped.sort(key=lambda r: (r.get("published", ""), r.get("tag", "")), reverse=True)
d["releases"] = deduped
d["last_updated"] = now
d.setdefault("source", source)
with open(index_path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
PYEOF

echo "index updated: $INDEX_FILE"
