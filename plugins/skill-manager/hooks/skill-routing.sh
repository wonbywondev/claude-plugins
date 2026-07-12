#!/usr/bin/env bash
# PreToolUse(Skill) hook — the runtime half of the relations ledger (ROUTING.md).
# When a skill is invoked, look it up in the ledger; if it has recorded relations,
# inject them via additionalContext (arrives alongside the skill body → the agent knows
# the combos/boundaries *while executing* the skill). No relations → silent, zero cost.
# This closes the gap where ledger consumption was deterministic only in add/recommend.
_SR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck disable=SC1091
source "$_SR_DIR/../lib/common.sh"
# shellcheck disable=SC1091
source "$_SR_DIR/../lib/routing.sh"

INPUT=$(cat)
skill=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ -n "$skill" ] || exit 0
base=$(sm_skill_base_name "$skill")

ledger="$(sm_skills_repo)/ROUTING.md"
rel=$(sm_routing_lookup "$ledger" "$base")
[ -n "$rel" ] || exit 0

jq -n --arg ctx "[skill-routing] \`$base\` 관계(원장 ROUTING.md):
$rel
→ 위 조합·경계·순서를 이 스킬 실행에 반영하라." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: $ctx
  }
}'
