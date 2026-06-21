# Phase 6 — audit (frontmatter 검증 + invocation_name 확정)

AUD="$TMPDIR_ROOT/audit"; mkdir -p "$AUD"

# --- 이름 정규화 ---
assert_eq "normalize spaces/case"        "gpt-taste"             "$(sm_normalize_name 'GPT Taste')"
assert_eq "normalize underscores/symbols" "design-taste-frontend" "$(sm_normalize_name 'design_taste!!frontend')"
assert_eq "normalize trim/collapse hyphens" "foo-bar"            "$(sm_normalize_name '--Foo  Bar--')"

# --- invocation_name = frontmatter name (업스트림 폴더명 무시) ---
mkdir -p "$AUD/gpt-tasteskill"
printf -- '---\nname: gpt-taste\ndescription: d.\n---\n' > "$AUD/gpt-tasteskill/SKILL.md"
assert_eq "invocation from frontmatter name" "gpt-taste" "$(sm_audit_invocation "$AUD/gpt-tasteskill/SKILL.md" gpt-tasteskill)"

# --- name 없으면 upstream 폴더명 폴백(정규화) ---
mkdir -p "$AUD/Weird_Dir"
printf -- '---\ndescription: d.\n---\n' > "$AUD/Weird_Dir/SKILL.md"
assert_eq "invocation fallback to upstream dir" "weird-dir" "$(sm_audit_invocation "$AUD/Weird_Dir/SKILL.md" Weird_Dir)"

# --- audit_check: 유효=빈출력, 누락 보고 ---
mkdir -p "$AUD/valid"; printf -- '---\nname: v\ndescription: d.\n---\n' > "$AUD/valid/SKILL.md"
assert_eq "audit ok → empty" "" "$(sm_audit_check "$AUD/valid/SKILL.md")"
mkdir -p "$AUD/noname"; printf -- '---\ndescription: d.\n---\n' > "$AUD/noname/SKILL.md"
assert_contains "audit reports missing name" "missing:name" "$(sm_audit_check "$AUD/noname/SKILL.md")"
mkdir -p "$AUD/nodesc"; printf -- '---\nname: n\n---\n' > "$AUD/nodesc/SKILL.md"
assert_contains "audit reports missing description" "missing:description" "$(sm_audit_check "$AUD/nodesc/SKILL.md")"
