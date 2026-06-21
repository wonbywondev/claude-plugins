# Phase 4 — digest (purpose-digest 생성 배선; digest 내용 자체는 LLM/오케스트레이션)

DG="$TMPDIR_ROOT/digest"; mkdir -p "$DG"
printf -- '---\nname: dg\ndescription: front desc.\n---\nThis skill does FOO and BAR.\nMore body here.\n' > "$DG/SKILL.md"

# --- body 추출: frontmatter 제외 ---
dg_body="$(sm_digest_body "$DG/SKILL.md")"
assert_contains "body has content" "This skill does FOO and BAR" "$dg_body"
if printf '%s' "$dg_body" | grep -q "front desc"; then
  echo -e "${RED}FAIL${NC}: body excludes frontmatter"; FAIL=$((FAIL+1))
else echo -e "${GREEN}PASS${NC}: body excludes frontmatter"; PASS=$((PASS+1)); fi

# --- frontmatter 없는 파일 = 전체 본문 ---
printf 'No frontmatter here.\nLine two.\n' > "$DG/plain.md"
assert_contains "plain file body = whole" "No frontmatter here." "$(sm_digest_body "$DG/plain.md")"

# --- digest 생성 프롬프트: 지시 + name + body 포함, frontmatter 미포함 ---
dg_p="$(sm_digest_prompt "$DG/SKILL.md" dg)"
assert_contains "prompt asks 1-2 line purpose" "1-2" "$dg_p"
assert_contains "prompt includes skill name" "dg" "$dg_p"
assert_contains "prompt includes body" "FOO and BAR" "$dg_p"
