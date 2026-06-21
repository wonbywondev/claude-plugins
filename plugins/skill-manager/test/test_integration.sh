# Phase 11 — integration (결정적 체인 e2e: fetch→candidates→audit→place→register→link)
# (digest/dedup 판정은 LLM/서브에이전트라 제외 — 스크립트 합성만 검증)

# 모의 업스트림 repo (지저분한 폴더명 + LICENSE)
INT_SRC="$TMPDIR_ROOT/int-src"
mkdir -p "$INT_SRC/skills/Cool_Skill"
printf -- '---\nname: cool-skill\ndescription: Use when you need cool things.\n---\nbody\n' > "$INT_SRC/skills/Cool_Skill/SKILL.md"
printf 'MIT License\n' > "$INT_SRC/LICENSE"

# 격리된 scope
IO1="$SKILLS_REPO"; IO2="$GLOBAL_SKILLS_DIR"; IO3="$SKILL_MANAGER_HOME"
export SKILLS_REPO="$TMPDIR_ROOT/int-central" GLOBAL_SKILLS_DIR="$TMPDIR_ROOT/int-global" SKILL_MANAGER_HOME="$TMPDIR_ROOT/int-home"
mkdir -p "$SKILLS_REPO" "$GLOBAL_SKILLS_DIR" "$SKILL_MANAGER_HOME"

int_staged="$TMPDIR_ROOT/int-staged"
sm_fetch_clone "$INT_SRC" "$int_staged" >/dev/null
int_cand="$(sm_fetch_candidates "$int_staged")"
assert_eq "integration: 1 candidate" "1" "$(printf '%s\n' "$int_cand" | grep -c .)"

int_rel="$(printf '%s\n' "$int_cand" | head -1 | cut -f1)"
int_inv="$(sm_audit_invocation "$int_staged/$int_rel/SKILL.md" "$(basename "$int_rel")")"
assert_eq "integration: invocation renamed to frontmatter name" "cool-skill" "$int_inv"

int_dest="$(sm_place "$int_staged/$int_rel" "$int_inv" "" "$int_staged/LICENSE")"
assert_file_exists "integration: placed SKILL.md" "$SKILLS_REPO/cool-skill/SKILL.md"
assert_file_exists "integration: LICENSE carried" "$SKILLS_REPO/cool-skill/LICENSE"

sm_register_upsert "$int_inv" source="$INT_SRC" source_type=local digest="cool skill does cool things" scope=global
assert_eq "integration: registered digest" "cool skill does cool things" "$(sm_register_get cool-skill digest)"

int_link="$(sm_link "$int_dest" "$int_inv" global)"
assert_symlink "integration: linked into global (flat)" "$GLOBAL_SKILLS_DIR/cool-skill"
assert_eq "integration: enumerated in central repo" "cool-skill" "$(sm_list_skills | grep -x cool-skill)"

export SKILLS_REPO="$IO1"; export GLOBAL_SKILLS_DIR="$IO2"; export SKILL_MANAGER_HOME="$IO3"
