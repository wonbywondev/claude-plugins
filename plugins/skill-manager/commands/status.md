---
description: Show skill-manager registry status (installed skills, digests, scope, provenance)
argument-hint: [skill-name]
---

Show skill-manager registry status. Argument (optional skill name): **$ARGUMENTS**

```bash
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
source "${CLAUDE_PLUGIN_ROOT}/lib/register.sh"
reg="$(sm_registry_path)"
echo "Registry: $reg"
[ -f "$reg" ] || { echo "(no registry yet)"; exit 0; }
python3 - "$reg" "$ARGUMENTS" <<'PY'
import json,sys
reg=sys.argv[1]; q=sys.argv[2].strip() if len(sys.argv)>2 else ""
d=json.load(open(reg)); skills=d.get("skills",{})
def show(n,e):
    print(f"\n# {n}")
    for k in ("source","source_type","scope","license","upstream_dir","fork_commit","link_mode"):
        if e.get(k): print(f"  {k}: {e[k]}")
    if e.get("digest"): print(f"  digest: {e['digest']}")
if q and q in skills: show(q,skills[q])
else:
    print(f"{len(skills)} skill(s) registered:")
    for n in sorted(skills): print(f"  - {n}  [{skills[n].get('scope','?')}]  {skills[n].get('digest','')[:60]}")
PY
```

Also cross-check: skills in the registry whose symlink is missing or dangling, and skills in `SKILLS_REPO` not yet registered (candidates for lazy digest backfill).
