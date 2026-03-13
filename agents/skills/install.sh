#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/sources.sh"

SKILLS_INSTALL_ROOT="${SKILLS_INSTALL_ROOT:-$HOME/.skills-installed}"
BACKUP_SUFFIX="${BACKUP_SUFFIX:-.backup}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d%H%M%S)}"

CONSUMER_SKILL_LINKS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.config/alma/skills"
  "$HOME/.gemini/antigravity/skills"
  "$HOME/.openclaw/skills"
)

backup_path() {
  local path="$1"

  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return
  fi

  local backup="${path}${BACKUP_SUFFIX}.${TIMESTAMP}"
  mv "$path" "$backup"
  rm -rf "${path}${BACKUP_SUFFIX}"
  ln -s "$backup" "${path}${BACKUP_SUFFIX}"
}

ensure_parent_dir() {
  mkdir -p "$(dirname "$1")"
}

link_entry() {
  local target="$1"
  local link_path="$2"

  ensure_parent_dir "$link_path"

  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    return
  fi

  rm -rf "$link_path"
  ln -s "$target" "$link_path"
}

repoint_consumer_link() {
  local target="$1"
  local link_path="$2"

  ensure_parent_dir "$link_path"

  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    return
  fi

  backup_path "$link_path"
  link_entry "$target" "$link_path"
}

discover_skill_dirs() {
  local root="$1"

  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | sort
}

rebuild_install_root() {
  rm -rf "$SKILLS_INSTALL_ROOT"
  mkdir -p "$SKILLS_INSTALL_ROOT"

  while IFS=$'\t' read -r label root; do
    [ -n "$root" ] || continue

    while IFS= read -r skill_dir; do
      [ -n "$skill_dir" ] || continue
      local skill_name
      skill_name="$(basename "$skill_dir")"
      local link_path="$SKILLS_INSTALL_ROOT/$skill_name"

      if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        printf 'INFO: keeping higher-priority skill %s, skipping %s from %s\n' "$skill_name" "$skill_name" "$label" >&2
        continue
      fi

      ln -s "$skill_dir" "$link_path"
    done < <(discover_skill_dirs "$root")
  done < <(list_skill_sources)
}

main() {
  rebuild_install_root

  local consumer_link
  for consumer_link in "${CONSUMER_SKILL_LINKS[@]}"; do
    repoint_consumer_link "$SKILLS_INSTALL_ROOT" "$consumer_link"
  done
}

main "$@"
