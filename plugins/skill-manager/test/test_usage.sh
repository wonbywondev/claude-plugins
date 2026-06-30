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
