#!/usr/bin/env bash
# skill-manager — select: curate which candidates to install (deterministic signals).
# LLM/사용자가 최종 결정; 이 단계는 superseded·already-installed·tool-overlap 신호를 산출.

sm_select_base()    { printf '%s' "$1" | sed -E 's/-v[0-9]+$//'; }
sm_select_version() { case "$1" in *-v[0-9]*) printf '%s' "$1" | sed -E 's/.*-v([0-9]+)$/\1/';; *) printf '999999';; esac; }

# names(newline) → superseded names (same base, lower version than a sibling)
sm_superseded() {
  printf '%s\n' "$1" | awk '
    function base(n){ sub(/-v[0-9]+$/,"",n); return n }
    function ver(n){ if (n ~ /-v[0-9]+$/){ sub(/.*-v/,"",n); return n+0 } return 999999 }
    { if($0=="") next; nm[NR]=$0; b=base($0); v=ver($0); if(!(b in mx)||v>mx[b]) mx[b]=v; bb[NR]=b; vv[NR]=v }
    END { for(i=1;i<=NR;i++) if(nm[i]!="" && vv[i]<mx[bb[i]]) print nm[i] }
  '
}

# candidate TSV (rel\tname\tdesc) [+ tool-keyword csv] → decision TSV (name\tdecision\treason)
# decision: keep | exclude(superseded|already-installed) | flag(tool-overlap:<kw>)
sm_select_filter() {
  local tsv="$1" toolkw="${2:-}"
  local names superseded installed tab
  tab="$(printf '\t')"
  names="$(printf '%s\n' "$tsv" | awk -F'\t' 'NF{print $2}')"
  superseded="$(sm_superseded "$names")"
  installed="$(sm_list_skills)"
  printf '%s\n' "$tsv" | while IFS="$tab" read -r rel name desc; do
    [ -n "$name" ] || continue
    local decision="keep" reason="" kw hay oldifs
    if printf '%s\n' "$superseded" | grep -qx "$name"; then
      decision="exclude"; reason="superseded"
    elif printf '%s\n' "$installed" | grep -qx "$name"; then
      decision="exclude"; reason="already-installed"
    elif [ -n "$toolkw" ]; then
      hay="$(printf '%s %s' "$name" "$desc" | tr 'A-Z' 'a-z')"
      oldifs="$IFS"; IFS=','
      for kw in $toolkw; do
        kw="$(printf '%s' "$kw" | tr 'A-Z' 'a-z' | sed 's/^ *//;s/ *$//')"
        [ -n "$kw" ] || continue
        case "$hay" in *"$kw"*) decision="flag"; reason="tool-overlap:$kw"; break;; esac
      done
      IFS="$oldifs"
    fi
    printf '%s\t%s\t%s\n' "$name" "$decision" "$reason"
  done
}
