#!/usr/bin/env bash
# skill-usage: aggregate Skill-tool invocations across session transcripts → usage stats.
# Use: spot ACTIVE skills that are rarely used (description sits in every session's context →
# token cost) and propose demoting them to dormant. NOT for dormant skills (always 0 — they
# can't be invoked while unlinked) and NOT a recommend signal (need-match is the primary one).

# sm_usage_db [db] → same TSV from the telemetry DB (~/dev/agent/data/claude-code-toolcalls.db).
# READ-ONLY consumer: SELECT only — the DB is owned by its importer (schema contract in
# ~/dev/agent/data/README.md: "하네스당 DB 1개, 타 DB 불가침"). skill-manager never writes there.
# Prefer this over the jsonl scan: incremental/idempotent import vs O(all transcripts) rescan.
sm_usage_db() {
  local db="${1:-$HOME/dev/agent/data/claude-code-toolcalls.db}"
  [ -f "$db" ] || return 0
  sqlite3 -separator $'\t' "file:$db?mode=ro" \
    "SELECT input_summary, COUNT(*), MAX(date(ts)) FROM calls WHERE tool='Skill' GROUP BY input_summary ORDER BY 2 DESC, 1;" 2>/dev/null
}

# sm_usage_auto [db] [projects_dir] → DB if present, else jsonl fallback.
sm_usage_auto() {
  local db="${1:-$HOME/dev/agent/data/claude-code-toolcalls.db}" dir="${2:-$HOME/.claude/projects}"
  if [ -f "$db" ]; then sm_usage_db "$db"; else sm_usage "$dir"; fi
}

# sm_usage [projects_dir] → TSV "skill<TAB>count<TAB>last_used(YYYY-MM-DD)", count desc.
# Fallback path (no telemetry DB): full scan of session transcripts — O(all jsonl), slower.
sm_usage() {
  local dir="${1:-$HOME/.claude/projects}"
  [ -d "$dir" ] || return 0
  find "$dir" -name '*.jsonl' -print0 2>/dev/null | xargs -0 cat 2>/dev/null | python3 -c '
import json, sys
from collections import defaultdict
cnt = defaultdict(int); last = {}
for line in sys.stdin:
    try:
        d = json.loads(line)
    except Exception:
        continue
    ts = d.get("timestamp", "")
    msg = d.get("message", {})
    content = msg.get("content", []) if isinstance(msg, dict) else []
    if not isinstance(content, list):
        continue
    for c in content:
        if isinstance(c, dict) and c.get("type") == "tool_use" and c.get("name") == "Skill":
            s = (c.get("input") or {}).get("skill")
            if s:
                cnt[s] += 1
                if ts > last.get(s, ""):
                    last[s] = ts
for s in sorted(cnt, key=lambda k: (-cnt[k], k)):
    lu = last.get(s, "")[:10]
    print(f"{s}\t{cnt[s]}\t{lu}")
'
}
