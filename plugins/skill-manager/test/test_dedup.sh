# Phase 5 — dedup: 어휘 프리필터(LLM 0) + 트리거 키워드 교집합

dd_corpus="$(printf '%s\t%s\n' \
  "korean-spell-check"  "correct korean spelling grammar text proofread" \
  "pdf"                 "extract text from pdf documents pages" \
  "naver-news-search"   "search naver news articles korea")"

# --- 프리필터: 유사 질의 → 해당 스킬이 top ---
dd_top="$(sm_prefilter "correct korean spelling and grammar in text" "$dd_corpus" 3 0.05)"
assert_eq "prefilter top hit = korean-spell-check" "korean-spell-check" "$(printf '%s\n' "$dd_top" | head -1 | cut -f1)"

# --- 프리필터: 무관 질의 → 결과 없음(조기종료, LLM 0) ---
dd_none="$(sm_prefilter "deploy kubernetes cluster helm charts pods" "$dd_corpus" 3 0.10)"
assert_eq "prefilter unrelated → empty" "0" "$(printf '%s\n' "$dd_none" | grep -c .)"

# --- 프리필터: top-K 제한 ---
dd_k="$(sm_prefilter "korea text search news documents" "$dd_corpus" 2 0.0)"
assert_eq "prefilter respects K=2" "2" "$(printf '%s\n' "$dd_k" | grep -c .)"

# --- 트리거 키워드 교집합 ---
assert_eq "shared keywords (one)"  "design" "$(sm_shared_keywords 'design,frontend' 'design,backend')"
assert_eq "shared keywords (none)" ""       "$(sm_shared_keywords 'a,b' 'c,d')"
assert_eq "shared keywords (sorted multi)" "$(printf 'design\nmotion')" "$(sm_shared_keywords 'motion,design,foo' 'design,motion')"

# --- sm_dedup_corpus: add 시 기존 전체와 비교하도록 전체 카탈로그 + registry digest overlay ---
sm_register_upsert "pdf" digest="extract pdf TESTMARK digest"
dd_dc="$(sm_dedup_corpus)"
assert_eq "dedup corpus = 전체 owned 스킬 망라" "$(sm_list_skills | grep -c .)" "$(printf '%s\n' "$dd_dc" | grep -c .)"
assert_eq "registry digest가 corpus text로(desc 덮어씀)" "extract pdf TESTMARK digest" "$(printf '%s\n' "$dd_dc" | awk -F'\t' '$1=="pdf"{print $2}')"
