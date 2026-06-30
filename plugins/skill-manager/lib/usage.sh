#!/usr/bin/env bash
# skill-usage: aggregate Skill-tool invocations across session transcripts → usage stats.
# Use: spot ACTIVE skills that are rarely used (description sits in every session's context →
# token cost) and propose demoting them to dormant. NOT for dormant skills (always 0 — they
# can't be invoked while unlinked) and NOT a recommend signal (need-match is the primary one).

# sm_usage [projects_dir] → TSV "skill<TAB>count<TAB>last_used(YYYY-MM-DD)", count desc.
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
