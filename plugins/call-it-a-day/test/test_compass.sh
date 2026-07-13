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

# --- linked worktree(raw git / Orca 공통) → 게이트 판정 스킵 ("worktree") ---
# 정책: 격리 트리는 잠정 작업(폐기 가능) + Orca 기본 병합=push+PR → 정합은 주 체크아웃에서 회수.
# compass가 setup hook으로 심링크돼 "존재"해도 게이트가 물면 안 된다(= 쓰기 유예 정책).
WT="$(mktemp -d)"
git init -q "$WT/main-co"
git -C "$WT/main-co" config user.email t@t; git -C "$WT/main-co" config user.name t
mkdir "$WT/main-co/compass"; echo ctx > "$WT/main-co/compass/context.md"; echo v1 > "$WT/main-co/app.rb"
printf 'compass/\n' > "$WT/main-co/.gitignore"
git -C "$WT/main-co" add -A >/dev/null 2>&1; git -C "$WT/main-co" commit -qm init
git -C "$WT/main-co" worktree add -q "$WT/wt" -b feat 2>/dev/null

# compass 유무와 무관하게 linked worktree면 일관되게 스킵(호출자 입장에서 판정 자체가 무의미)
assert_eq "worktree: compass 부재여도 → worktree(스킵)" "worktree" "$(cad_compass_stale "$WT/wt")"

ln -s "$WT/main-co/compass" "$WT/wt/compass"     # setup hook이 심링크로 읽기 상속시킨 상황
touch -t 202601010000 "$WT/main-co/compass/context.md"
touch -t 203001010000 "$WT/wt/app.rb"            # 소스가 compass보다 최신 = 평소라면 stale
assert_eq "worktree: compass 있고 소스 최신이어도 → worktree(스킵)" "worktree" "$(cad_compass_stale "$WT/wt")"

touch -t 203001010000 "$WT/main-co/app.rb"
assert_eq "주 체크아웃: 회귀 없이 stale 판정" "stale" "$(cad_compass_stale "$WT/main-co")"
git -C "$WT/main-co" worktree remove "$WT/wt" --force 2>/dev/null; rm -rf "$WT"
