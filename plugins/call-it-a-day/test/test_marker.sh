# per-project day marker: cad_marker_* take a project dir (default $PWD)
A="$(mktemp -d)"; B="$(mktemp -d)"
cad_marker_clear "$A" 2>/dev/null; cad_marker_clear "$B" 2>/dev/null

assert_eq "A 초기 inactive"        "inactive"  "$(cad_marker_active "$A" && echo active || echo inactive)"
assert_eq "A start → started"      "started"   "$(cad_marker_start "$A")"
assert_eq "A active"               "active"    "$(cad_marker_active "$A" && echo active || echo inactive)"
assert_eq "B는 독립(여전히 inactive)" "inactive" "$(cad_marker_active "$B" && echo active || echo inactive)"
assert_eq "A started_at 기록"      "yes"       "$([ -n "$(cad_marker_started_at "$A")" ] && echo yes || echo no)"
assert_eq "A 재start → carryover"  "carryover" "$(cad_marker_start "$A")"
assert_eq "A clear 후 inactive"    "inactive"  "$(cad_marker_clear "$A"; cad_marker_active "$A" && echo active || echo inactive)"
rm -rf "$A" "$B"
