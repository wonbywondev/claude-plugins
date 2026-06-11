# user-prompt-submit hook: stdin JSON {prompt} → classify → marker/nudge/trigger on stdout
HOOK="$PLUGIN_DIR/hooks/user-prompt-submit.sh"
cad_marker_clear

# morning → starts day + injects nudge
out=$(printf '{"prompt":"좋은 아침"}' | bash "$HOOK")
assert_eq      "morning → 마커 active"  "active" "$(cad_marker_active && echo active || echo inactive)"
assert_contains "morning → 넛지(wiki) 주입" "wiki" "$out"

# active day + normal prompt → nudge injected
out=$(printf '{"prompt":"이 함수 고쳐줘"}' | bash "$HOOK")
assert_contains "active+일반 → 넛지(wiki)" "wiki" "$out"

# wrap → trigger wrap-up
out=$(printf '{"prompt":"하루 마무리하자"}' | bash "$HOOK")
assert_contains "wrap → 마무리 트리거" "마무리" "$out"

# inactive + normal → no output
cad_marker_clear
out=$(printf '{"prompt":"그냥 일반 질문"}' | bash "$HOOK")
assert_eq "inactive+일반 → 출력 없음" "" "$out"
