#!/usr/bin/env bash
# skill-curator — classify a skill as global or project-specific
# Usage: classify.sh <skill-name>
# Output: "global" or "project"
set -euo pipefail

SKILL_NAME="${1:?Usage: classify.sh <skill-name>}"

# Namespaced skills (contain /) → project-specific
if [[ "$SKILL_NAME" == */* ]]; then
  echo "project"
  exit 0
fi

# gstack-* → global (infrastructure/methodology skills)
case "$SKILL_NAME" in
  gstack-*) echo "global"; exit 0 ;;
esac

# Top-level flat skills → global by default
echo "global"
