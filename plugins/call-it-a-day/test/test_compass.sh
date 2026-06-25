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

# --- git 프로젝트: untracked 노이즈(log/tmp 등 .gitignore된 것)는 stale 판정서 제외 ---
# (rails runner가 log/*.log mtime만 올리는 false-positive 차단)
GP="$(mktemp -d)"
git -C "$GP" init -q
mkdir -p "$GP/compass"
printf 'ctx\n' > "$GP/compass/context.md"; printf 'code\n' > "$GP/app.rb"
git -C "$GP" add -A >/dev/null 2>&1
git -C "$GP" -c user.email=t@t.io -c user.name=t commit -qm init >/dev/null 2>&1
touch -t 202601010000 "$GP/compass/context.md" "$GP/app.rb"   # tracked 전부 과거
mkdir -p "$GP/log"; touch -t 203001010000 "$GP/log/development.log"  # untracked 노이즈만 미래
assert_eq "git: untracked 노이즈(log) 무시 → fresh" "fresh" "$(cad_compass_stale "$GP")"
touch -t 203001010000 "$GP/app.rb"                            # tracked 코드가 최신
assert_eq "git: tracked 코드 최신 → stale"          "stale" "$(cad_compass_stale "$GP")"
rm -rf "$GP"
