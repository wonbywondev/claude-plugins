# cad_compass_stale <project_dir> → stale | fresh | no-compass | bad-path
P="$(mktemp -d)"
assert_eq "compass 폴더 없음 → no-compass" "no-compass" "$(cad_compass_stale "$P")"
# 존재하지 않는 경로(이름만 줬거나 오타) → bad-path : 진짜 no-compass와 구분(false no-compass 오진 차단)
assert_eq "존재 안 하는 경로 → bad-path" "bad-path" "$(cad_compass_stale "$P/nope")"

mkdir -p "$P/compass"
touch -t 202606100900 "$P/compass/plan.md"
touch -t 202606101000 "$P/src.py"              # src가 compass보다 최신
assert_eq "src 최신 → stale"   "stale" "$(cad_compass_stale "$P")"

touch -t 202606101100 "$P/compass/plan.md"     # compass가 최신
assert_eq "compass 최신 → fresh" "fresh" "$(cad_compass_stale "$P")"

# 노이즈 경로(.git/node_modules)는 무시돼야 (compass보다 최신이어도 fresh 유지)
mkdir -p "$P/.git" "$P/node_modules"
touch -t 202606101200 "$P/.git/HEAD" "$P/node_modules/x.js"
assert_eq ".git/node_modules 무시 → fresh" "fresh" "$(cad_compass_stale "$P")"

rm -rf "$P"
