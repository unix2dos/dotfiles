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

claude_state() {
  CLAUDE_AVAILABLE=false
  CLAUDE_MARKETPLACE=false
  CLAUDE_INSTALLED=false
  CLAUDE_ENABLED=false
  CLAUDE_VERSION=""

  command -v claude >/dev/null 2>&1 || return 0
  CLAUDE_AVAILABLE=true
  claude plugin marketplace list 2>/dev/null | grep -q '❯ ponytail$' && CLAUDE_MARKETPLACE=true
  local plugins
  plugins=$(claude plugin list --json 2>/dev/null) || return 0
  if json_has "$plugins" '.[] | select(.id == "ponytail@ponytail")'; then
    CLAUDE_INSTALLED=true
    CLAUDE_VERSION=$(printf '%s' "$plugins" | yq -p=json -r '.[] | select(.id == "ponytail@ponytail") | .version' | head -n 1)
    json_has "$plugins" '.[] | select(.id == "ponytail@ponytail" and .enabled == true)' && CLAUDE_ENABLED=true
  fi
  return 0
}

preview_claude() {
  claude_state
  if [[ "$CLAUDE_AVAILABLE" == false ]]; then
    echo "  Claude      unavailable — skipped"
  elif [[ "$CLAUDE_INSTALLED" == true ]]; then
    local state="disabled"
    [[ "$CLAUDE_ENABLED" == true ]] && state="enabled"
    echo "  Claude      ${CLAUDE_VERSION:-unknown}  installed, ${state} → marketplace update"
  else
    echo "  Claude      not installed → add marketplace and install"
  fi
}

dry_run_claude() {
  claude_state
  if [[ "$CLAUDE_AVAILABLE" == false ]]; then
    echo "  Claude: unavailable — skipped"
    return 0
  fi
  if [[ "$CLAUDE_MARKETPLACE" == true ]]; then
    echo "  [DRY-RUN] claude plugin marketplace update ponytail"
  else
    echo "  [DRY-RUN] claude plugin marketplace add DietrichGebert/ponytail"
  fi
  [[ "$CLAUDE_INSTALLED" == true ]] || echo "  [DRY-RUN] claude plugin install ponytail@ponytail"
}

install_claude() {
  claude_state
  if [[ "$CLAUDE_AVAILABLE" == false ]]; then
    echo "  Claude: unavailable — skipped"
    return 0
  fi
  if [[ "$CLAUDE_MARKETPLACE" == true ]]; then
    claude plugin marketplace update ponytail >/dev/null
    echo "  Claude marketplace updated: ponytail"
  else
    claude plugin marketplace add DietrichGebert/ponytail >/dev/null
    echo "  Claude marketplace added: ponytail"
  fi

  claude_state
  if [[ "$CLAUDE_INSTALLED" == false ]]; then
    claude plugin install ponytail@ponytail >/dev/null
    echo "  Claude plugin installed: ponytail@ponytail"
  elif [[ "$CLAUDE_ENABLED" == false ]]; then
    echo "  WARNING: Claude plugin is disabled; run: claude plugin enable ponytail@ponytail"
  else
    echo "  Claude plugin ready: ponytail@ponytail ${CLAUDE_VERSION}"
  fi
  echo "  Start a new Claude Code session; /ponytail should report the active mode"
}

devin_bin() {
  if command -v devin >/dev/null 2>&1; then command -v devin; return 0; fi
  local app=/Applications/Devin.app/Contents/Resources/app/extensions/windsurf/devin/bin/devin
  [[ -x "$app" ]] && { echo "$app"; return 0; }
  return 1
}

devin_state() {
  DEVIN_AVAILABLE=false
  DEVIN_LOGGED_IN=false
  DEVIN_INSTALLED=false
  DEVIN_BIN=$(devin_bin 2>/dev/null) || return 0
  DEVIN_AVAILABLE=true
  local list
  list=$("$DEVIN_BIN" plugins list 2>&1) || { echo "$list" | grep -q "logged in" && return 0; }
  DEVIN_LOGGED_IN=true
  echo "$list" | grep -q "ponytail" && DEVIN_INSTALLED=true
  return 0
}

preview_devin() {
  devin_state
  if [[ "$DEVIN_AVAILABLE" == false ]]; then
    echo "  Devin       unavailable — skipped"
  elif [[ "$DEVIN_LOGGED_IN" == false ]]; then
    echo "  Devin       not logged in → run: devin auth login"
  elif [[ "$DEVIN_INSTALLED" == true ]]; then
    echo "  Devin       installed → plugins update"
  else
    echo "  Devin       not installed → plugins install"
  fi
}

dry_run_devin() {
  devin_state
  if [[ "$DEVIN_AVAILABLE" == false ]]; then
    echo "  Devin: unavailable — skipped"
    return 0
  fi
  if [[ "$DEVIN_INSTALLED" == true ]]; then
    echo "  [DRY-RUN] devin plugins update ponytail"
  else
    echo "  [DRY-RUN] devin plugins install DietrichGebert/ponytail"
  fi
}

install_devin() {
  devin_state
  if [[ "$DEVIN_AVAILABLE" == false ]]; then
    echo "  Devin: unavailable — skipped"
    return 0
  fi
  if [[ "$DEVIN_LOGGED_IN" == false ]]; then
    echo "  WARNING: Devin CLI not logged in; run: $DEVIN_BIN auth login, then rerun"
    return 0
  fi
  if [[ "$DEVIN_INSTALLED" == true ]]; then
    "$DEVIN_BIN" plugins update ponytail >/dev/null
    echo "  Devin plugin updated: ponytail"
  else
    "$DEVIN_BIN" plugins install DietrichGebert/ponytail >/dev/null
    echo "  Devin plugin installed: ponytail"
  fi
  echo "  Skills available as /ponytail:ponytail and /ponytail:ponytail-review"
}

opencode_state() {
  OPENCODE_AVAILABLE=false
  OPENCODE_INSTALLED=false
  OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
  command -v opencode >/dev/null 2>&1 || return 0
  OPENCODE_AVAILABLE=true
  [[ -f "$OPENCODE_CONFIG" ]] || return 0
  yq -p=json -e '.plugin[] | select(. == "@dietrichgebert/ponytail")' "$OPENCODE_CONFIG" >/dev/null 2>&1 && OPENCODE_INSTALLED=true
  return 0
}

preview_opencode() {
  opencode_state
  if [[ "$OPENCODE_AVAILABLE" == false ]]; then
    echo "  OpenCode    unavailable — skipped"
  elif [[ "$OPENCODE_INSTALLED" == true ]]; then
    echo "  OpenCode    installed → keep plugin entry"
  else
    echo "  OpenCode    not installed → add plugin entry to opencode.json"
  fi
}

dry_run_opencode() {
  opencode_state
  if [[ "$OPENCODE_AVAILABLE" == false ]]; then
    echo "  OpenCode: unavailable — skipped"
    return 0
  fi
  [[ "$OPENCODE_INSTALLED" == true ]] || echo "  [DRY-RUN] add \"@dietrichgebert/ponytail\" to .plugin in $OPENCODE_CONFIG"
}

install_opencode() {
  opencode_state
  if [[ "$OPENCODE_AVAILABLE" == false ]]; then
    echo "  OpenCode: unavailable — skipped"
    return 0
  fi
  if [[ "$OPENCODE_INSTALLED" == true ]]; then
    echo "  OpenCode plugin ready: @dietrichgebert/ponytail"
    return 0
  fi
  mkdir -p "$(dirname "$OPENCODE_CONFIG")"
  [[ -f "$OPENCODE_CONFIG" ]] || echo '{}' > "$OPENCODE_CONFIG"
  yq -p=json -o=json -i '.plugin = ((.plugin // []) + ["@dietrichgebert/ponytail"])' "$OPENCODE_CONFIG"
  echo "  OpenCode plugin added to $OPENCODE_CONFIG: @dietrichgebert/ponytail"
  echo "  OpenCode fetches the npm package on next start"
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
    preview:claude) preview_claude ;;
    dry-run:claude) dry_run_claude ;;
    install:claude) install_claude ;;
    preview:devin) preview_devin ;;
    dry-run:devin) dry_run_devin ;;
    install:devin) install_devin ;;
    preview:opencode) preview_opencode ;;
    dry-run:opencode) dry_run_opencode ;;
    install:opencode) install_opencode ;;
    *) echo "ERROR: ponytail installer does not support host: $host" >&2; exit 1 ;;
  esac
done
