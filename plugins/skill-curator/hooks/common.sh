#!/usr/bin/env bash
# skill-curator — shared helpers
# Sourced by hooks and test runner. Do not execute directly.

SKILLS_REPO="${SKILLS_REPO:-$HOME/dev/claude_tools/skills}"
GLOBAL_SKILLS_DIR="${GLOBAL_SKILLS_DIR:-$HOME/.claude/skills}"

project_skills_dir() {
  local project_dir="${1:-$PWD}"
  echo "$project_dir/.claude/skills"
}

# List all skills in the central repo.
# Flat skills: "skill-name"
# Namespaced skills: "namespace/skill-name"
# Skips: .claude, node_modules, .git, test, gstack source dir (but keeps gstack-* skills)
list_central_skills() {
  [ -d "$SKILLS_REPO" ] || return 0

  for entry in "$SKILLS_REPO"/*/; do
    [ -d "$entry" ] || continue
    local name
    name="$(basename "$entry")"

    # Skip non-skill directories
    case "$name" in
      .claude|node_modules|.git|test|.DS_Store) continue ;;
    esac

    # Check if this is a namespace folder (contains subdirs with SKILL.md)
    local is_namespace=0
    for sub in "$entry"/*/; do
      if [ -f "$sub/SKILL.md" ]; then
        is_namespace=1
        break
      fi
    done

    if [ "$is_namespace" -eq 1 ]; then
      # Namespace: list sub-skills
      for sub in "$entry"/*/; do
        [ -f "$sub/SKILL.md" ] || continue
        echo "$name/$(basename "$sub")"
      done
    elif [ -f "$entry/SKILL.md" ]; then
      # Flat skill
      echo "$name"
    fi
  done
}

# Detect project stack from file markers.
# Outputs one tag per line: node, python, n8n, notion, docker, gstack, etc.
detect_stack() {
  local project_dir="${1:-$PWD}"
  local tags=()

  # Node/JS/TS
  if [ -f "$project_dir/package.json" ]; then
    tags+=(node)

    local pkg_content
    pkg_content="$(cat "$project_dir/package.json" 2>/dev/null)"

    # n8n detection
    if echo "$pkg_content" | grep -qi 'n8n'; then
      tags+=(n8n)
    fi

    # Notion detection
    if echo "$pkg_content" | grep -qi 'notion'; then
      tags+=(notion)
    fi
  fi

  # n8n config file
  if [ -f "$project_dir/.n8nrc" ] || [ -f "$project_dir/.n8n" ]; then
    if [[ ! " ${tags[*]} " =~ " n8n " ]]; then
      tags+=(n8n)
    fi
  fi

  # Python
  if [ -f "$project_dir/requirements.txt" ] || \
     [ -f "$project_dir/pyproject.toml" ] || \
     [ -f "$project_dir/Pipfile" ] || \
     [ -f "$project_dir/setup.py" ]; then
    tags+=(python)
  fi

  # Docker
  if [ -f "$project_dir/docker-compose.yml" ] || \
     [ -f "$project_dir/docker-compose.yaml" ] || \
     [ -f "$project_dir/Dockerfile" ]; then
    tags+=(docker)
  fi

  # Google Cloud / gstack
  if [ -f "$project_dir/.gcloudignore" ] || \
     [ -f "$project_dir/app.yaml" ]; then
    tags+=(gstack)
  fi

  # Output tags, one per line
  printf '%s\n' "${tags[@]}"
}

# Match detected stack tags to available skills in central repo.
# Input: space-separated or newline-separated tags
# Output: matching skill paths (namespace/skill or skill-name)
match_skills() {
  local tags="$1"
  [ -z "$tags" ] && return 0

  local all_skills
  all_skills="$(list_central_skills)"
  [ -z "$all_skills" ] && return 0

  local matched=()
  while IFS= read -r skill; do
    local namespace="${skill%%/*}"
    # If skill has a namespace and that namespace matches a tag
    if [[ "$skill" == */* ]]; then
      if echo "$tags" | grep -qw "$namespace"; then
        matched+=("$skill")
      fi
    else
      # Flat skill: check if name contains a tag
      for tag in $tags; do
        case "$skill" in
          gstack-*)
            if [ "$tag" = "gstack" ]; then
              matched+=("$skill")
              break
            fi
            ;;
        esac
      done
    fi
  done <<< "$all_skills"

  printf '%s\n' "${matched[@]}"
}
