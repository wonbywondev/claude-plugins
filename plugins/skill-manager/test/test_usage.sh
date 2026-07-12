# sm_usage <projects_dir> → "skill<TAB>count<TAB>last_used(YYYY-MM-DD)" (count 내림차순)
# transcript jsonl의 Skill tool_use(input.skill) 집계 → 활성 스킬 사용통계.

UD="$(mktemp -d)"
mkdir -p "$UD/projA" "$UD/projB"
cat > "$UD/projA/s1.jsonl" <<'EOF'
{"timestamp":"2026-06-01T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"taste-skill"}}]}}
{"timestamp":"2026-06-04T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"taste-skill"}}]}}
{"timestamp":"2026-06-02T10:00:00Z","message":{"content":[{"type":"text","text":"noise, not a skill"}]}}
{"timestamp":"2026-06-02T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}
EOF
cat > "$UD/projB/s2.jsonl" <<'EOF'
{"timestamp":"2026-06-03T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"gstack"}}]}}
{"timestamp":"2026-06-05T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"taste-skill"}}]}}
EOF

USG="$(sm_usage "$UD")"
assert_eq "taste-skill count=3"           "3"          "$(printf '%s\n' "$USG" | awk -F'\t' '$1=="taste-skill"{print $2}')"
assert_eq "gstack count=1"                "1"          "$(printf '%s\n' "$USG" | awk -F'\t' '$1=="gstack"{print $2}')"
assert_eq "taste-skill last_used=06-05"   "2026-06-05" "$(printf '%s\n' "$USG" | awk -F'\t' '$1=="taste-skill"{print $3}')"
assert_eq "Skill 아닌 tool_use 무시(2종만)" "2"          "$(printf '%s\n' "$USG" | grep -c .)"
assert_eq "정렬 top = taste-skill(최다)"   "taste-skill" "$(printf '%s\n' "$USG" | head -1 | cut -f1)"

rm -rf "$UD"

# --- sm_usage_db: telemetry DB(calls) 우선 경로 — 같은 TSV 포맷, SELECT만 ---
UDB="$(mktemp -d)/toolcalls.db"
sqlite3 "$UDB" "CREATE TABLE calls(pk TEXT PRIMARY KEY, ts TEXT, tool TEXT, input_summary TEXT);
INSERT INTO calls VALUES
 ('a','2026-06-01T10:00:00Z','Skill','taste-skill'),
 ('b','2026-06-04T10:00:00Z','Skill','taste-skill'),
 ('c','2026-06-05T10:00:00Z','Skill','taste-skill'),
 ('d','2026-06-03T10:00:00Z','Skill','gstack'),
 ('e','2026-06-02T10:00:00Z','Bash','ls -la');"
UDBOUT="$(sm_usage_db "$UDB")"
assert_eq "db: taste-skill count=3"          "3"           "$(printf '%s\n' "$UDBOUT" | awk -F'\t' '$1=="taste-skill"{print $2}')"
assert_eq "db: last_used=최신 date"          "2026-06-05"  "$(printf '%s\n' "$UDBOUT" | awk -F'\t' '$1=="taste-skill"{print $3}')"
assert_eq "db: Skill 외 tool 무시(2종만)"     "2"           "$(printf '%s\n' "$UDBOUT" | grep -c .)"
assert_eq "db: 정렬 top=최다"                "taste-skill" "$(printf '%s\n' "$UDBOUT" | head -1 | cut -f1)"
# --- sm_usage_auto: DB 있으면 DB, 없으면 jsonl 폴백 ---
UAD="$(mktemp -d)"; mkdir -p "$UAD/p"
printf '%s\n' '{"timestamp":"2026-06-09T10:00:00Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"only-jsonl"}}]}}' > "$UAD/p/s.jsonl"
assert_eq "auto: DB 존재 → DB 결과"          "taste-skill" "$(sm_usage_auto "$UDB" "$UAD" | head -1 | cut -f1)"
assert_eq "auto: DB 부재 → jsonl 폴백"       "only-jsonl"  "$(sm_usage_auto "$UDB.nope" "$UAD" | head -1 | cut -f1)"
rm -rf "$(dirname "$UDB")" "$UAD"
