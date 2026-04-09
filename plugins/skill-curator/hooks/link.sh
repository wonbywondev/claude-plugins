#!/usr/bin/env bash
# skill-curator — symlink management
# Usage:
#   link.sh --link <skill> --scope <global|project> [--project-dir <path>]
#   link.sh --unlink <skill> --scope <global|project> [--project-dir <path>]
#   link.sh --status --scope <global|project|all> [--project-dir <path>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ACTION=""
SKILL=""
SCOPE=""
PROJECT_DIR="${PWD}"

while [ $# -gt 0 ]; do
  case "$1" in
    --link)   ACTION="link";   SKILL="$2"; shift 2 ;;
    --unlink) ACTION="unlink"; SKILL="$2"; shift 2 ;;
    --status) ACTION="status"; shift ;;
    --scope)  SCOPE="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

resolve_skill_path() {
  local skill="$1"
  if [[ "$skill" == */* ]]; then
    echo "$SKILLS_REPO/$skill"
  else
    echo "$SKILLS_REPO/$skill"
  fi
}

resolve_target_dir() {
  local scope="$1"
  if [ "$scope" = "global" ]; then
    echo "$GLOBAL_SKILLS_DIR"
  else
    echo "$(project_skills_dir "$PROJECT_DIR")"
  fi
}

do_link() {
  local skill="$1" scope="$2"
  local source_path target_dir link_name

  source_path="$(resolve_skill_path "$skill")"
  if [ ! -d "$source_path" ]; then
    echo "Error: skill '$skill' not found in central repo at $source_path" >&2
    exit 1
  fi

  target_dir="$(resolve_target_dir "$scope")"
  mkdir -p "$target_dir"

  # For namespaced skills, link the namespace folder
  if [[ "$skill" == */* ]]; then
    local namespace="${skill%%/*}"
    link_name="$namespace"
    source_path="$SKILLS_REPO/$namespace"
  else
    link_name="$skill"
  fi

  local link_path="$target_dir/$link_name"
  if [ -L "$link_path" ]; then
    echo "Already linked: $link_name → $(readlink "$link_path")"
    return 0
  fi

  ln -s "$source_path" "$link_path"
  echo "Linked: $link_name → $source_path ($scope)"
}

do_unlink() {
  local skill="$1" scope="$2"
  local target_dir link_name

  target_dir="$(resolve_target_dir "$scope")"

  if [[ "$skill" == */* ]]; then
    link_name="${skill%%/*}"
  else
    link_name="$skill"
  fi

  local link_path="$target_dir/$link_name"
  if [ -L "$link_path" ]; then
    rm "$link_path"
    echo "Unlinked: $link_name ($scope)"
  else
    echo "Not linked: $link_name ($scope)" >&2
  fi
}

do_status() {
  local scope="$1"

  show_links() {
    local dir="$1" label="$2"
    echo "[$label]"
    [ -d "$dir" ] || { echo "  (none)"; return 0; }
    local found=0
    for entry in "$dir"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      [ -L "$entry" ] || continue
      local name target
      name="$(basename "$entry")"
      target="$(readlink "$entry")"
      if [ -d "$entry" ]; then
        echo "  $name → $target"
      else
        echo "  $name → $target (BROKEN)"
      fi
      found=1
    done
    if [ "$found" -eq 0 ]; then echo "  (none)"; fi
  }

  case "$scope" in
    global)
      show_links "$GLOBAL_SKILLS_DIR" "Global"
      ;;
    project)
      local pdir
      pdir="$(project_skills_dir "$PROJECT_DIR")"
      show_links "$pdir" "Project"
      ;;
    all)
      show_links "$GLOBAL_SKILLS_DIR" "Global"
      echo ""
      local pdir
      pdir="$(project_skills_dir "$PROJECT_DIR")"
      show_links "$pdir" "Project"
      ;;
  esac
}

case "$ACTION" in
  link)   do_link "$SKILL" "$SCOPE" ;;
  unlink) do_unlink "$SKILL" "$SCOPE" ;;
  status) do_status "$SCOPE" ;;
  *)      echo "Usage: link.sh --link|--unlink|--status ..." >&2; exit 1 ;;
esac
