#!/usr/bin/env bash
# skill-manager — audit: frontmatter validation + invocation_name resolution.

# Normalize an arbitrary string into a valid skill dir / invocation name.
sm_normalize_name() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9' '-' | sed -E 's/-+/-/g; s/^-+//; s/-+$//'
}

# Resolve the invocation name (= place folder name): frontmatter `name` normalized,
# falling back to the upstream dir name when frontmatter has no name.
sm_audit_invocation() {
  local f="$1" upstream="$2" name
  name="$(sm_frontmatter_field "$f" name)"
  if [ -n "$name" ]; then sm_normalize_name "$name"; else sm_normalize_name "$upstream"; fi
}

# Validate frontmatter. Prints issue tokens (missing:name / missing:description); empty = ok.
sm_audit_check() {
  local f="$1" n d
  n="$(sm_frontmatter_field "$f" name)"
  d="$(sm_frontmatter_field "$f" description)"
  [ -n "$n" ] || echo "missing:name"
  [ -n "$d" ] || echo "missing:description"
}
