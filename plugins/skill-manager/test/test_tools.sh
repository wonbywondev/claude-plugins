# v1.1 — tool-overlap capability map (sm_installed_tool_keywords)

TM="$TMPDIR_ROOT/tools.map"
{
  printf 'pencil\timage,design,mockup\tknowledge/libraries/pencil.md\n'
  printf 'codegraph\tcode graph,symbol\t\n'
  printf 'gh\tgithub,issue\t\n'
  printf '# comment line ignored\n'
  printf '\n'
  printf 'pencil2\timage,extra\t\n'
} > "$TM"

# 설치된 도구만 키워드 산출 (installed set 주입 = 결정적)
tk="$(sm_installed_tool_keywords "$TM" "pencil,gh")"
assert_contains "installed pencil → image kw" "image" "$tk"
assert_contains "installed gh → github kw" "github" "$tk"
if printf '%s' "$tk" | grep -q "symbol"; then
  echo -e "${RED}FAIL${NC}: 미설치 codegraph 키워드 제외"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: 미설치 codegraph 키워드 제외"; PASS=$((PASS+1)); fi

# 아무것도 설치 안 됨 → 빈 출력 (live discovery 안 타도록 non-empty sentinel)
assert_eq "none installed → empty" "" "$(sm_installed_tool_keywords "$TM" "__none__")"

# 도구 간 중복 키워드 dedup (pencil+pencil2 둘 다 image → 1회)
tk2="$(sm_installed_tool_keywords "$TM" "pencil,pencil2")"
assert_eq "중복 키워드 dedup(image 1회)" "1" "$(printf '%s' "$tk2" | tr ',' '\n' | grep -cx 'image')"

# 배선: 설치된 pencil → imagegen 후보가 tool-overlap 플래그
tk_cand="$(printf '%s\t%s\t%s\n' "." "imagegen-frontend-web" "premium image generation references")"
tk_dec="$(sm_select_filter "$tk_cand" "$(sm_installed_tool_keywords "$TM" "pencil")")"
assert_contains "imagegen → tool-overlap via map" "flag" "$tk_dec"
