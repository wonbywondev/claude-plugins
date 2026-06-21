# v3.0 — recommend: sm_catalog (보유 스킬 name⇥desc 카탈로그)

RC="$TMPDIR_ROOT/rec-repo"
mkdir -p "$RC/alpha" "$RC/grp/beta" "$RC/grp/gamma" "$RC/umb/x" "$RC/umb/y"
printf -- '---\nname: alpha\ndescription: Alpha does A.\n---\n' > "$RC/alpha/SKILL.md"
printf -- '---\nname: beta\ndescription: Beta does B.\n---\n'   > "$RC/grp/beta/SKILL.md"
printf -- '---\nname: gamma\ndescription: Gamma does C.\n---\n' > "$RC/grp/gamma/SKILL.md"
# umbrella: 루트 SKILL.md + 자식 → 1엔트리(통째), 자식 미열거
printf -- '---\nname: umb\ndescription: Umbrella U.\n---\n'    > "$RC/umb/SKILL.md"
printf -- '---\nname: x\ndescription: x.\n---\n'               > "$RC/umb/x/SKILL.md"
printf -- '---\nname: y\ndescription: y.\n---\n'               > "$RC/umb/y/SKILL.md"

rc_cat="$(sm_catalog "$RC")"

# 엔트리 수: alpha, beta, gamma, umb = 4 (x,y 제외)
assert_eq "catalog: 4 entries (umbrella=1)" "4" "$(printf '%s\n' "$rc_cat" | grep -c .)"
assert_contains "catalog alpha + desc" "Alpha does A." "$rc_cat"
assert_contains "catalog grp leaf beta" "Beta does B." "$rc_cat"
assert_contains "catalog umbrella umb" "Umbrella U." "$rc_cat"
if printf '%s\n' "$rc_cat" | cut -f1 | grep -qx "x"; then
  echo -e "${RED}FAIL${NC}: 응집번들 자식(x) 미열거"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 응집번들 자식(x) 미열거"; PASS=$((PASS+1)); fi

# sm_list_skills 와 이름 일관
assert_eq "catalog names == sm_list_skills" "$(sm_list_skills "$RC")" "$(printf '%s\n' "$rc_cat" | cut -f1 | sort)"

# zsh-safe: 빈 그룹(자식 없음)이어도 에러 없이 통과
mkdir -p "$RC/emptygrp"
assert_eq "empty group → no crash, still 4" "4" "$(sm_catalog "$RC" | grep -c .)"

# sm_skill_dir: 이름 → 활성화용 dir 경로 (sm_link에 넘김)
assert_eq "skill_dir flat alpha"      "$RC/alpha"     "$(sm_skill_dir alpha "$RC")"
assert_eq "skill_dir group leaf gamma" "$RC/grp/gamma" "$(sm_skill_dir gamma "$RC")"
assert_eq "skill_dir umbrella umb"    "$RC/umb"       "$(sm_skill_dir umb "$RC")"
assert_eq "skill_dir missing → empty" ""             "$(sm_skill_dir nope "$RC")"
