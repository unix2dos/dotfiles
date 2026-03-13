#!/bin/bash

set -euo pipefail

DEFAULT_OWNED_SKILLS_ROOT="/Users/liuwei/workspace/skills"
DEFAULT_GENERATED_SKILLS_ROOT="/Users/liuwei/workspace/compat-ed3d/targets/codex/skills"

owned_skills_root() {
  printf '%s\n' "${OWNED_SKILLS_ROOT:-$DEFAULT_OWNED_SKILLS_ROOT}"
}

generated_skills_root() {
  printf '%s\n' "${GENERATED_SKILLS_ROOT:-$DEFAULT_GENERATED_SKILLS_ROOT}"
}

third_party_skills_root() {
  printf '%s\n' "${THIRD_PARTY_SKILLS_ROOT:-$HOME/.codex/superpowers/skills}"
}

list_skill_sources() {
  local label
  local path

  for label in owned generated third-party; do
    case "$label" in
      owned)
        path="$(owned_skills_root)"
        ;;
      generated)
        path="$(generated_skills_root)"
        ;;
      third-party)
        path="$(third_party_skills_root)"
        ;;
    esac

    if [ -d "$path" ]; then
      printf '%s\t%s\n' "$label" "$path"
    else
      printf 'WARN: missing %s skills root: %s\n' "$label" "$path" >&2
    fi
  done
}
