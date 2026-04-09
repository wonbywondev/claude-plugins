#!/usr/bin/env bash
# Tests for classify.sh

CLASSIFY="$PLUGIN_DIR/hooks/classify.sh"

# Namespaced skills → project
output="$(bash "$CLASSIFY" "notion/knowledge-capture")"
assert_eq "classify namespaced notion skill as project" "project" "$output"

output="$(bash "$CLASSIFY" "n8n/code-python")"
assert_eq "classify namespaced n8n skill as project" "project" "$output"

# gstack-* → global
output="$(bash "$CLASSIFY" "gstack-qa")"
assert_eq "classify gstack skill as global" "global" "$output"

# Generic top-level → global
output="$(bash "$CLASSIFY" "systematic-debugging")"
assert_eq "classify generic top-level skill as global" "global" "$output"

output="$(bash "$CLASSIFY" "pdf")"
assert_eq "classify utility skill as global" "global" "$output"
