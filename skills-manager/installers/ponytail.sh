#!/bin/bash
set -euo pipefail

ACTION="${1:-}"
[[ -n "$ACTION" ]] && shift

case "$ACTION" in
  preview|dry-run|install) ;;
  *) echo "ERROR: usage: ponytail.sh <preview|dry-run|install> <host...>" >&2; exit 1 ;;
esac

command -v yq >/dev/null 2>&1 || { echo "ERROR: yq is required by ponytail installer" >&2; exit 1; }

json_has() {
  local json="$1" expression="$2"
  printf '%s' "$json" | yq -p=json -e "$expression" >/dev/null 2>&1
}

codex_state() {
  CODEX_AVAILABLE=false
  CODEX_MARKETPLACE=false
  CODEX_INSTALLED=false
  CODEX_ENABLED=false
  CODEX_VERSION=""

  command -v codex >/dev/null 2>&1 || return 0
  CODEX_AVAILABLE=true
  CODEX_MARKETPLACES=$(codex plugin marketplace list --json) || return 1
  CODEX_PLUGINS=$(codex plugin list --json) || return 1

  json_has "$CODEX_MARKETPLACES" '.marketplaces[] | select(.name == "ponytail")' && CODEX_MARKETPLACE=true
  if json_has "$CODEX_PLUGINS" '.installed[] | select(.pluginId == "ponytail@ponytail" and .installed == true)'; then
    CODEX_INSTALLED=true
    CODEX_VERSION=$(printf '%s' "$CODEX_PLUGINS" | yq -p=json -r '.installed[] | select(.pluginId == "ponytail@ponytail") | .version' | head -n 1)
    json_has "$CODEX_PLUGINS" '.installed[] | select(.pluginId == "ponytail@ponytail" and .enabled == true)' && CODEX_ENABLED=true
  fi
}

preview_codex() {
  codex_state
  if [[ "$CODEX_AVAILABLE" == false ]]; then
    echo "  Codex       unavailable — skipped"
  elif [[ "$CODEX_INSTALLED" == true ]]; then
    local state="disabled"
    [[ "$CODEX_ENABLED" == true ]] && state="enabled"
    echo "  Codex       ${CODEX_VERSION:-unknown}  installed, ${state} → marketplace upgrade"
    echo "              exposes 6 plugin Skills outside ~/.agents/skills"
  else
    echo "  Codex       not installed → add marketplace and install"
  fi
}

dry_run_codex() {
  codex_state
  if [[ "$CODEX_AVAILABLE" == false ]]; then
    echo "  Codex: unavailable — skipped"
    return 0
  fi
  if [[ "$CODEX_MARKETPLACE" == true ]]; then
    echo "  [DRY-RUN] codex plugin marketplace upgrade ponytail --json"
  else
    echo "  [DRY-RUN] codex plugin marketplace add DietrichGebert/ponytail --json"
  fi
  if [[ "$CODEX_INSTALLED" == false ]]; then
    echo "  [DRY-RUN] codex plugin add ponytail@ponytail --json"
  elif [[ "$CODEX_ENABLED" == false ]]; then
    echo "  [DRY-RUN] ponytail is installed but disabled; enable it manually in /plugins"
  fi
}

install_codex() {
  codex_state
  if [[ "$CODEX_AVAILABLE" == false ]]; then
    echo "  Codex: unavailable — skipped"
    return 0
  fi
  if [[ "$CODEX_MARKETPLACE" == true ]]; then
    codex plugin marketplace upgrade ponytail --json >/dev/null
    echo "  Codex marketplace updated: ponytail"
  else
    codex plugin marketplace add DietrichGebert/ponytail --json >/dev/null
    echo "  Codex marketplace added: ponytail"
  fi

  codex_state
  if [[ "$CODEX_INSTALLED" == false ]]; then
    codex plugin add ponytail@ponytail --json >/dev/null
    echo "  Codex plugin installed: ponytail@ponytail"
  elif [[ "$CODEX_ENABLED" == false ]]; then
    echo "  WARNING: Codex plugin is disabled; enable ponytail in /plugins"
  else
    echo "  Codex plugin ready: ponytail@ponytail ${CODEX_VERSION}"
  fi
  echo "  Restart Codex, review changed hooks in /hooks, then start a new task"
}

cursor_state() {
  CURSOR_AVAILABLE=false
  CURSOR_INSTALLED=false
  CURSOR_CURRENT=false
  CURSOR_TARGET="$HOME/.cursor/plugins/local/ponytail"

  if command -v cursor >/dev/null 2>&1 || [[ -d /Applications/Cursor.app ]]; then CURSOR_AVAILABLE=true; fi
  if [[ -f "$CURSOR_TARGET/.cursor-plugin/plugin.json" && -f "$CURSOR_TARGET/rules/ponytail.mdc" ]]; then
    CURSOR_INSTALLED=true
    local source
    source=$(cursor_rule_source 2>/dev/null || true)
    [[ -n "$source" ]] && cmp -s "$source" "$CURSOR_TARGET/rules/ponytail.mdc" && CURSOR_CURRENT=true
  fi
}

cursor_rule_source() {
  if [[ -n "${PONYTAIL_CURSOR_RULE_SOURCE:-}" && -f "$PONYTAIL_CURSOR_RULE_SOURCE" ]]; then
    echo "$PONYTAIL_CURSOR_RULE_SOURCE"
    return 0
  fi
  if command -v codex >/dev/null 2>&1; then
    local root
    root=$(codex plugin marketplace list --json 2>/dev/null | yq -p=json -r '.marketplaces[] | select(.name == "ponytail") | .root' | head -n 1)
    if [[ -n "$root" && -f "$root/.cursor/rules/ponytail.mdc" ]]; then
      echo "$root/.cursor/rules/ponytail.mdc"
      return 0
    fi
  fi
  return 1
}

preview_cursor() {
  cursor_state
  if [[ "$CURSOR_AVAILABLE" == false ]]; then
    echo "  Cursor      unavailable — skipped"
  elif [[ "$CURSOR_INSTALLED" == false ]]; then
    echo "  Cursor      not installed → create local rule plugin"
  elif [[ "$CURSOR_CURRENT" == true ]]; then
    echo "  Cursor      installed, current → keep local rule plugin"
  else
    echo "  Cursor      installed → refresh local rule plugin"
  fi
  [[ "$CURSOR_AVAILABLE" == false ]] || echo "              instruction-only: no Ponytail modes, hooks, or commands"
}

dry_run_cursor() {
  cursor_state
  if [[ "$CURSOR_AVAILABLE" == false ]]; then
    echo "  Cursor: unavailable — skipped"
    return 0
  fi
  echo "  [DRY-RUN] refresh $CURSOR_TARGET from Ponytail .cursor/rules/ponytail.mdc"
  echo "  [DRY-RUN] restart Cursor or run Developer: Reload Window"
}

install_cursor() {
  cursor_state
  if [[ "$CURSOR_AVAILABLE" == false ]]; then
    echo "  Cursor: unavailable — skipped"
    return 0
  fi

  local source temp_rule=""
  source=$(cursor_rule_source 2>/dev/null || true)
  if [[ -z "$source" ]]; then
    command -v curl >/dev/null 2>&1 || { echo "ERROR: Cursor Ponytail install needs codex marketplace data or curl" >&2; return 1; }
    temp_rule=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/DietrichGebert/ponytail/main/.cursor/rules/ponytail.mdc" -o "$temp_rule"
    source="$temp_rule"
  fi

  mkdir -p "$CURSOR_TARGET/.cursor-plugin" "$CURSOR_TARGET/rules"
  cp "$source" "$CURSOR_TARGET/rules/ponytail.mdc"
  printf '%s\n' \
    '{' \
    '  "name": "ponytail",' \
    '  "displayName": "Ponytail",' \
    '  "version": "0.0.0",' \
    '  "description": "Ponytail lazy senior developer rule for Cursor",' \
    '  "author": { "name": "Dietrich Gebert" },' \
    '  "license": "MIT"' \
    '}' > "$CURSOR_TARGET/.cursor-plugin/plugin.json"
  [[ -z "$temp_rule" ]] || rm -f "$temp_rule"

  [[ -f "$CURSOR_TARGET/rules/ponytail.mdc" ]] || { echo "ERROR: Cursor Ponytail rule verification failed" >&2; return 1; }
  echo "  Cursor local rule plugin ready: $CURSOR_TARGET"
  echo "  Restart Cursor or run Developer: Reload Window"
}

[[ "$#" -gt 0 ]] || { echo "ERROR: ponytail installer requires at least one host" >&2; exit 1; }
for host in "$@"; do
  case "$ACTION:$host" in
    preview:codex) preview_codex ;;
    dry-run:codex) dry_run_codex ;;
    install:codex) install_codex ;;
    preview:cursor) preview_cursor ;;
    dry-run:cursor) dry_run_cursor ;;
    install:cursor) install_cursor ;;
    *) echo "ERROR: ponytail installer does not support host: $host" >&2; exit 1 ;;
  esac
done
