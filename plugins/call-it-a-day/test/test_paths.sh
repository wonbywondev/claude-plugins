# State dir resolution: CALL_IT_A_DAY_HOME > CLAUDE_PLUGIN_DATA (Claude Code runtime standard) > plugins/data fallback.
# Re-source common.sh in a subshell with controlled env (the var is assigned at source time).
_cad_home_with() {
  ( unset CALL_IT_A_DAY_HOME CLAUDE_PLUGIN_DATA; eval "$1"; source "$PLUGIN_DIR/hooks/common.sh"; printf '%s' "$CALL_IT_A_DAY_HOME" )
}
assert_eq "CALL_IT_A_DAY_HOME default → plugins/data 표준" \
  "$HOME/.claude/plugins/data/call-it-a-day-wonbywondev-plugins" "$(_cad_home_with ':')"
assert_eq "CLAUDE_PLUGIN_DATA 존중(런타임)" \
  "/tmp/cad-pd-test" "$(_cad_home_with 'export CLAUDE_PLUGIN_DATA=/tmp/cad-pd-test')"
assert_eq "CALL_IT_A_DAY_HOME 최우선" \
  "/tmp/cad-explicit" "$(_cad_home_with 'export CLAUDE_PLUGIN_DATA=/tmp/cad-pd-test CALL_IT_A_DAY_HOME=/tmp/cad-explicit')"
