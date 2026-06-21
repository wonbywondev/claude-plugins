#!/usr/bin/env bash
# skill-manager — dedup: lexical prefilter (0 LLM tokens) + trigger-keyword overlap.
# digest-judgment / body-reread / routing-note are LLM/subagent steps (orchestration), not here.

# Lexical prefilter. query text vs corpus TSV "name\ttext" → top-K "name\tscore" (Jaccard), score>=floor.
# Most new installs: max score < floor → no candidates → caller skips the LLM judge entirely.
sm_prefilter() {
  local query="$1" corpus="$2" k="${3:-8}" floor="${4:-0.08}" tab
  tab="$(printf '\t')"
  printf '%s\n' "$corpus" | awk -F'\t' -v q="$query" -v FL="$floor" '
    BEGIN{
      split("the and for use when with this that you your are can will from into not skill skills agent claude the are",sw," ")
      for(i in sw) stop[sw[i]]=1
      n=split(tolower(q),qa,/[^a-z0-9]+/)
      for(i=1;i<=n;i++){ t=qa[i]; if(length(t)>=3 && !stop[t]) qset[t]=1 }
      qn=0; for(t in qset) qn++
    }
    NF>=2{
      name=$1; txt=$2
      split("",cset)
      m=split(tolower(txt),ta,/[^a-z0-9]+/)
      cn=0; inter=0
      for(i=1;i<=m;i++){ t=ta[i]; if(length(t)>=3 && !stop[t] && !(t in cset)){ cset[t]=1; cn++; if(t in qset) inter++ } }
      uni=qn+cn-inter
      score=(uni>0)? inter/uni : 0
      if(score>=FL) printf "%s\t%.4f\n", name, score
    }
  ' | sort -t"$tab" -k2 -nr | head -n "$k"
}

# Intersection of two CSV/space keyword lists → newline-sorted shared keywords (lowercased).
sm_shared_keywords() {
  awk -v A="$1" -v B="$2" 'BEGIN{
    na=split(A,aa,/[, ]+/); for(i=1;i<=na;i++){ t=tolower(aa[i]); if(t!="") set[t]=1 }
    nb=split(B,bb,/[, ]+/); for(i=1;i<=nb;i++){ t=tolower(bb[i]); if(t!="" && (t in set)) out[t]=1 }
    n=0; for(t in out) o[n++]=t
    for(i=0;i<n;i++) for(j=i+1;j<n;j++) if(o[j]<o[i]){tmp=o[i];o[i]=o[j];o[j]=tmp}
    for(i=0;i<n;i++) print o[i]
  }'
}

# Build the dedup corpus for `add`: EVERY owned skill (catalog description) with registry
# purpose-digests overlaid where present (digests are sharper than descriptions). This makes
# dedup compare a new skill against the *whole* central repo (~400), not just registry entries.
# One python pass (not per-skill). Output TSV: name<TAB>text → feed straight to sm_prefilter.
sm_dedup_corpus() {
  local repo="${1:-$(sm_skills_repo)}" reg
  reg="$(sm_registry_path)"
  sm_catalog "$repo" | python3 -c '
import json, sys
reg = sys.argv[1]
digests = {}
try:
    with open(reg) as f:
        data = json.load(f)
    for n, rec in (data.get("skills") or {}).items():
        d = rec.get("digest") if isinstance(rec, dict) else None
        if d:
            digests[n] = d
except Exception:
    pass
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    name, _, desc = line.partition("\t")
    print(f"{name}\t{digests.get(name, desc)}")
' "$reg"
}
