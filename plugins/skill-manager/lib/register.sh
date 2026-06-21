#!/usr/bin/env bash
# skill-manager — register: provenance + digest registry (registry.json).
# JSON handled by python3 (robust, atomic write, corruption recovery).

sm_registry_path() { printf '%s/registry.json' "$(sm_home)"; }

# sm_register_upsert <invocation_name> key=value [key=value ...]   (merges into skills[name])
sm_register_upsert() {
  local name="$1"; shift
  local reg; reg="$(sm_registry_path)"
  mkdir -p "$(dirname "$reg")"
  python3 - "$reg" "$name" "$@" <<'PY'
import json, sys, os
reg, name = sys.argv[1], sys.argv[2]
pairs = sys.argv[3:]
data = {"skills": {}}
if os.path.exists(reg):
    try:
        with open(reg) as f:
            data = json.load(f)
        if not isinstance(data, dict) or not isinstance(data.get("skills"), dict):
            raise ValueError("bad shape")
    except Exception:
        try: os.replace(reg, reg + ".bak")   # corruption recovery
        except Exception: pass
        data = {"skills": {}}
entry = data["skills"].get(name, {})
for p in pairs:
    if "=" in p:
        k, v = p.split("=", 1)
        entry[k] = v
data["skills"][name] = entry
tmp = reg + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
os.replace(tmp, reg)   # atomic
PY
}

# sm_register_get <invocation_name> [field]   (field omitted → whole entry as JSON)
sm_register_get() {
  local name="$1" field="${2:-}" reg; reg="$(sm_registry_path)"
  [ -f "$reg" ] || return 0
  python3 - "$reg" "$name" "$field" <<'PY'
import json, sys
reg, name, field = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(reg))
except Exception:
    sys.exit(0)
e = d.get("skills", {}).get(name)
if e is None:
    sys.exit(0)
if field:
    v = e.get(field, "")
    print(v if isinstance(v, str) else json.dumps(v, ensure_ascii=False))
else:
    print(json.dumps(e, ensure_ascii=False))
PY
}
