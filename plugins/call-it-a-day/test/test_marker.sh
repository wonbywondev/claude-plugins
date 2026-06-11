# day marker: cad_marker_start / cad_marker_active / cad_marker_started_at / cad_marker_clear
cad_marker_clear 2>/dev/null || true   # clean slate

assert_eq "초기: inactive"                "inactive"  "$(cad_marker_active && echo active || echo inactive)"
assert_eq "start: started"                "started"   "$(cad_marker_start)"
assert_eq "start 후: active"              "active"    "$(cad_marker_active && echo active || echo inactive)"
assert_eq "started_at 기록됨"             "yes"       "$([ -n "$(cad_marker_started_at)" ] && echo yes || echo no)"
assert_eq "재 start(미마무리): carryover"  "carryover" "$(cad_marker_start)"
assert_eq "clear 후: inactive"            "inactive"  "$(cad_marker_clear; cad_marker_active && echo active || echo inactive)"
