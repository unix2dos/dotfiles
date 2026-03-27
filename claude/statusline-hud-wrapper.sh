#!/usr/bin/env bash
# Wrapper: run claude-hud, then append worktree label if applicable
input=$(cat)

# Run claude-hud
plugin_dir=$(ls -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 | cut -f2-)

hud_output=$(echo "$input" | "$HOME/.bun/bin/bun" "${plugin_dir}src/index.ts" 2>/dev/null)

# Detect worktree
cwd=$(echo "$input" | "$HOME/.bun/bin/bun" -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.cwd||d.workspace?.current_dir||'')" 2>/dev/null)
[ -z "$cwd" ] && cwd=$(pwd)

wt_label=""
if [ -d "$cwd" ]; then
  git_common=$(cd "$cwd" && git rev-parse --git-common-dir 2>/dev/null)
  git_dir=$(cd "$cwd" && git rev-parse --git-dir 2>/dev/null)
  if [ -n "$git_common" ] && [ -n "$git_dir" ] && [ "$git_common" != "$git_dir" ]; then
    wt_name=$(basename "$cwd")
    wt_label=" │ 🌳 wt:${wt_name}"
  fi
fi

printf '%s%s' "$hud_output" "$wt_label"
