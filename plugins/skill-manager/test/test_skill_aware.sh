# skill-aware UPS 훅 로직: dormant 스킬 + 활용의도 cue → 매칭
# (활성 스킬엔 침묵, 일반명사 스킬 false-positive 회피)

# --- sm_dormant_skills: owned 중 global 미링크만 ---
SA_REPO="$(mktemp -d)"; SA_GLOBAL="$(mktemp -d)"
mkdir -p "$SA_REPO/gstack" "$SA_REPO/korean" "$SA_REPO/taste-skill"
touch "$SA_REPO/gstack/SKILL.md" "$SA_REPO/korean/SKILL.md" "$SA_REPO/taste-skill/SKILL.md"
ln -s "$SA_REPO/taste-skill" "$SA_GLOBAL/taste-skill"   # taste-skill만 활성
assert_eq "dormant = 미링크만(gstack,korean)" "$(printf 'gstack\nkorean')" "$(sm_dormant_skills "$SA_REPO" "$SA_GLOBAL")"

# --- sm_aware_match: 이름 + 활용의도 둘 다일 때만 ---
DORM="$(printf 'gstack\nkorean\npdf')"
assert_eq "이름+활용의도 → 매치"        "gstack" "$(sm_aware_match 'gstack 써줘'        "$DORM")"
assert_eq "이름+활용(활용하자) → 매치"  "korean" "$(sm_aware_match 'korean 스킬 활용하자' "$DORM")"
assert_eq "이름만(질문) → 침묵"         ""       "$(sm_aware_match 'gstack이 뭐야?'      "$DORM")"
assert_eq "일반명사+비활용동사 → 침묵"  ""       "$(sm_aware_match 'pdf 만들어줘'        "$DORM")"
assert_eq "활성스킬(목록에 없음) → 침묵" ""      "$(sm_aware_match 'taste-skill 써줘'    "$DORM")"
assert_eq "무관 → 침묵"                 ""       "$(sm_aware_match '이거 버그 고쳐줘'    "$DORM")"

rm -rf "$SA_REPO" "$SA_GLOBAL"
