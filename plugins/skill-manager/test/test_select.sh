# Phase 3 — select (큐레이트 subset)

# 후보 TSV (rel \t name \t desc) — pdf 는 MOCK_CENTRAL 에 이미 존재
sel_cand="$(printf '%s\t%s\t%s\n' \
  "." "taste-skill"            "anti-slop frontend" \
  "." "taste-skill-v1"         "old version" \
  "." "bar-v1"                 "bar one" \
  "." "bar-v2"                 "bar two" \
  "." "pdf"                    "pdf skill" \
  "." "imagegen-frontend-web"  "premium image generation references" \
  "." "novel-thing"            "something brand new")"

sel_out="$(sm_select_filter "$sel_cand" "image,pencil")"

sel_dec() { printf '%s\n' "$sel_out" | awk -F'\t' -v n="$1" '$1==n{print $2 (($3!="")?":"$3:"")}'; }

assert_eq "taste-skill kept (latest)"            "keep"                      "$(sel_dec taste-skill)"
assert_eq "taste-skill-v1 superseded"            "exclude:superseded"        "$(sel_dec taste-skill-v1)"
assert_eq "bar-v1 superseded by bar-v2"          "exclude:superseded"        "$(sel_dec bar-v1)"
assert_eq "bar-v2 kept (highest)"                "keep"                      "$(sel_dec bar-v2)"
assert_eq "pdf already-installed"                "exclude:already-installed" "$(sel_dec pdf)"
assert_eq "imagegen tool-overlap flag"           "flag:tool-overlap:image"   "$(sel_dec imagegen-frontend-web)"
assert_eq "novel-thing kept"                     "keep"                      "$(sel_dec novel-thing)"

# base/version 헬퍼
assert_eq "base strips -vN"   "design-taste-frontend" "$(sm_select_base design-taste-frontend-v1)"
assert_eq "base no suffix"    "foo"                   "$(sm_select_base foo)"
assert_eq "version of -v2"    "2"                     "$(sm_select_version bar-v2)"
assert_eq "version no suffix" "999999"                "$(sm_select_version foo)"
