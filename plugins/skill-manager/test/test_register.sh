# Phase 8 — register (provenance + digest 레지스트리)

RG_OLD="$SKILL_MANAGER_HOME"
export SKILL_MANAGER_HOME="$TMPDIR_ROOT/reg-home"; mkdir -p "$SKILL_MANAGER_HOME"

# --- upsert + get ---
sm_register_upsert design-taste-frontend \
  source="https://github.com/Leonxlnx/taste-skill" source_type=git \
  digest="anti-slop frontend code skill" license=MIT scope=global upstream_dir=taste-skill
assert_eq "get source"      "https://github.com/Leonxlnx/taste-skill" "$(sm_register_get design-taste-frontend source)"
assert_eq "get digest"      "anti-slop frontend code skill"           "$(sm_register_get design-taste-frontend digest)"
assert_eq "get source_type" "git"                                     "$(sm_register_get design-taste-frontend source_type)"
assert_eq "get upstream_dir" "taste-skill"                            "$(sm_register_get design-taste-frontend upstream_dir)"

# --- 부분 업데이트는 기존 필드 보존 ---
sm_register_upsert design-taste-frontend scope=project:/foo
assert_eq "update preserves digest" "anti-slop frontend code skill" "$(sm_register_get design-taste-frontend digest)"
assert_eq "update changes scope"    "project:/foo"                  "$(sm_register_get design-taste-frontend scope)"

# --- 없는 키 → 빈 출력 ---
assert_eq "missing skill → empty" "" "$(sm_register_get nonexistent-skill digest)"

# --- 손상 복구: 깨진 JSON이어도 upsert 성공 + .bak 백업 ---
printf 'NOT JSON {{{' > "$SKILL_MANAGER_HOME/registry.json"
sm_register_upsert recovered digest=ok
assert_eq "recovery after corruption" "ok" "$(sm_register_get recovered digest)"
assert_file_exists "corrupt registry backed up" "$SKILL_MANAGER_HOME/registry.json.bak"

export SKILL_MANAGER_HOME="$RG_OLD"
