# compass-gate Stop 훅 로직 (cg_stop_cue / cg_decide)
source "$PLUGIN_DIR/hooks/compass-gate.sh"

# --- cg_stop_cue: 사용자 멈춤 의도 감지 (게이트 스킵 신호) ---
cg_stop_cue "오늘 여기서 마무리하자" && r=cue || r=no; assert_eq "마무리 → cue"      "cue" "$r"
cg_stop_cue "그만하자"               && r=cue || r=no; assert_eq "그만 → cue"        "cue" "$r"
cg_stop_cue "이건 나중에 할게"       && r=cue || r=no; assert_eq "나중에 → cue"      "cue" "$r"
cg_stop_cue "이 버그 고쳐줘"         && r=cue || r=no; assert_eq "작업요청 → no cue" "no"  "$r"
cg_stop_cue "compass 업데이트해줘"   && r=cue || r=no; assert_eq "compass작업 → no cue" "no" "$r"

# --- cg_decide: skip | block ---
assert_eq "stop_active=true → skip(무한방지)"   "skip"  "$(cg_decide true  stale       no)"
assert_eq "멈춤 cue → skip(사용자 존중)"        "skip"  "$(cg_decide false stale       yes)"
assert_eq "fresh → skip"                        "skip"  "$(cg_decide false fresh       no)"
assert_eq "no-compass → skip"                   "skip"  "$(cg_decide false no-compass  no)"
assert_eq "bad-path → skip"                     "skip"  "$(cg_decide false bad-path    no)"
assert_eq "stale+작업중+cue없음 → block"        "block" "$(cg_decide false stale       no)"
