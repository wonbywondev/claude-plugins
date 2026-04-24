#!/usr/bin/env bash
# fetch-new-releases.sh
#
# Fetches the latest Claude Code releases from anthropics/claude-code and
# writes one markdown file per release into upstream-updates/. Skips releases
# that already have a corresponding file. Idempotent — safe to rerun.
#
# Each generated file has YAML frontmatter for lifecycle tracking:
#   acknowledged: false   → flip to true once you've read the notes
#   applied:      false   → flip to true once plugin changes (if any) are done
#   impact:       null    → "none" | "docs-only" | "code" (set when acknowledging)
#   notes:        ""      → free-form per-release comment
#
# Environment:
#   GH_TOKEN / GITHUB_TOKEN must be set for `gh` CLI in CI contexts.

set -euo pipefail

# Resolve repo root from .github/scripts/ (two levels up)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT_DIR/upstream-updates"
mkdir -p "$OUT_DIR"

UPSTREAM_REPO="anthropics/claude-code"
LIMIT="${FETCH_LIMIT:-30}"

# Keyword set for plugin-relevance scanning. Hits are surfaced at the top of
# each generated file so the reviewer can eyeball impact quickly.
KEYWORDS='session|sessionId|cwd|parentUuid|hook|SessionStart|PostToolUse|slug|path encoding|NFC|NFD|[-/]resume|cleanupPeriodDays|projects directory|plugin|plugin\.json|marketplace\.json|hooks\.json|path-independent|hash\.txt|~/\.claude/projects'

new_count=0

while IFS='|' read -r PUBLISHED TAG; do
  DATE="${PUBLISHED:0:10}"
  OUT="$OUT_DIR/${DATE}-${TAG}.md"

  if [[ -f "$OUT" ]]; then
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

  {
    echo "---"
    echo "tag: $TAG"
    echo "published: $DATE"
    echo "url: $URL"
    echo "keyword_hits: $HITS"
    echo "acknowledged: false"
    echo "applied: false"
    echo "impact: null"
    echo "notes: \"\""
    echo "---"
    echo ""
    echo "# Claude Code $TAG ($DATE)"
    echo ""
    echo "Source: $URL"
    echo ""
    if [[ "$HITS" -gt 0 ]]; then
      echo "## Plugin-relevant keyword hits ($HITS)"
      echo ""
      echo '```'
      echo "$MATCHES"
      echo '```'
      echo ""
    else
      echo "## Plugin-relevant keyword hits"
      echo ""
      echo "_No keyword matches in the release body. Safe to mark acknowledged/applied without action after a quick skim._"
      echo ""
    fi
    echo "## Full release notes"
    echo ""
    echo "$BODY"
  } > "$OUT"

  echo "new: $(basename "$OUT") (hits: $HITS)"
  new_count=$((new_count + 1))
done < <(gh release list --repo "$UPSTREAM_REPO" --limit "$LIMIT" \
          --json tagName,publishedAt \
          --jq '.[] | "\(.publishedAt)|\(.tagName)"')

echo ""
echo "fetch-new-releases: $new_count new file(s)"
