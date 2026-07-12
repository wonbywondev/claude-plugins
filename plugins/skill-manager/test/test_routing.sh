# routing: ROUTING.md(관계 원장) 결정적 부분독 + 위생 lint
# 원장 포맷: ## 카테고리 섹션, 항목=단락(빈 줄 구분), 스킬명은 `백틱`, 행 자격=이름 2개 이상.

RT="$(mktemp -d)"; RF="$RT/ROUTING.md"
cat > "$RF" <<'EOF'
# ROUTING — 스킬 관계 원장

## 디자인

- `design-taste-frontend` ↔ `ui-ux-pro-max`: 차별화 우선=taste 주도 / 체계 우선=ui-ux 주도.

- `stop-slop` / `kill-ai-slop`: 글은 stop-slop, 웹 slop 정밀검출은 kill-ai-slop.

## 콘텐츠

- `content-pipeline` ↔ `cardnews-copy-review`: 카피 확정 단계 보조.
EOF

# --- lookup: 이름 포함 단락만 (섹션 무관 매칭) ---
rl_out="$(sm_routing_lookup "$RF" ui-ux-pro-max)"
assert_contains "lookup: 해당 단락 포함"        "차별화 우선" "$rl_out"
assert_eq       "lookup: 무관 단락 제외"         "0" "$(printf '%s' "$rl_out" | grep -c cardnews)"
assert_eq       "lookup: 없는 이름 → 빈 출력"    ""  "$(sm_routing_lookup "$RF" nonexistent-skill)"
rl_multi="$(sm_routing_lookup "$RF" kill-ai-slop cardnews-copy-review)"
assert_contains "lookup: 다중 이름 OR 매칭(1)"   "stop-slop" "$rl_multi"
assert_contains "lookup: 다중 이름 OR 매칭(2)"   "카피 확정" "$rl_multi"

# --- lint: 실존 검사 + 행 자격 ---
RREPO="$RT/repo"; mkdir -p "$RREPO"
for s in ui-ux-pro-max stop-slop content-pipeline cardnews-copy-review; do
  mkdir -p "$RREPO/$s"; touch "$RREPO/$s/SKILL.md"
done
# design-taste-frontend는 그룹 리프(taste-skill/ 하위) — 실환경과 동일. flat -d 검사면 놓침.
mkdir -p "$RREPO/taste-grp/design-taste-frontend"; touch "$RREPO/taste-grp/design-taste-frontend/SKILL.md"
# kill-ai-slop은 repo에 없음 → missing. extra 목록에 넣으면 통과.
rl_lint="$(sm_routing_lint "$RF" "$RREPO")"
assert_contains "lint: 미실존 스킬 감지"         "missing:kill-ai-slop" "$rl_lint"
assert_eq       "lint: extra 허용 시 클린"       "" "$(sm_routing_lint "$RF" "$RREPO" kill-ai-slop)"
# 행 자격: 이름 1개짜리 행 추가 → single 플래그
printf -- '\n- `stop-slop`: 혼자 재설명하는 행(금지 패턴).\n' >> "$RF"
assert_contains "lint: 이름 1개 행 플래그"       "single:" "$(sm_routing_lint "$RF" "$RREPO" kill-ai-slop)"

# --- 훅용 이름 정규화: 플러그인 네임스페이스 제거 ---
assert_eq "base name: 플러그인 네임스페이스 제거" "call-it-a-day" "$(sm_skill_base_name 'call-it-a-day:call-it-a-day')"
assert_eq "base name: 접두 다른 네임스페이스"      "recommend"     "$(sm_skill_base_name 'skill-manager:recommend')"
assert_eq "base name: 무네임스페이스 그대로"       "stop-slop"     "$(sm_skill_base_name 'stop-slop')"

rm -rf "$RT"
