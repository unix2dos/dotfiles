#!/usr/bin/env bash

set -euo pipefail

payload=$(cat)

model_name=$(printf '%s' "$payload" | jq -r '.model.display_name // .model.id // "unknown"')
model_param=$(printf '%s' "$payload" | jq -r '.model.param_summary // ""')
max_mode=$(printf '%s' "$payload" | jq -r '.model.max_mode // false')

used_pct=$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // 0')
remaining_pct=$(printf '%s' "$payload" | jq -r '.context_window.remaining_percentage // 0')
window_size=$(printf '%s' "$payload" | jq -r '.context_window.context_window_size // 0')
input_tokens=$(printf '%s' "$payload" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(printf '%s' "$payload" | jq -r '.context_window.total_output_tokens // 0')

cwd=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // ""')
worktree_name=$(printf '%s' "$payload" | jq -r '.worktree.name // ""')

used_int=$(printf '%.0f' "$used_pct")
remaining_int=$(printf '%.0f' "$remaining_pct")
percent_label="${used_int}%"

bar_width=12
filled=$(( used_int * bar_width / 100 ))
if [ "$filled" -lt 0 ]; then
  filled=0
fi
if [ "$filled" -gt "$bar_width" ]; then
  filled=$bar_width
fi
empty=$(( bar_width - filled ))

bar=""
if [ "$filled" -gt 0 ]; then
  printf -v fill_block "%${filled}s" ""
  bar="${fill_block// /#}"
fi
if [ "$empty" -gt 0 ]; then
  printf -v empty_block "%${empty}s" ""
  bar="${bar}${empty_block// /-}"
fi

model_label="$model_name"
if [ -n "$model_param" ]; then
  model_label="$model_label $model_param"
fi
if [ "$max_mode" = "true" ]; then
  model_label="$model_label MAX"
fi

token_usage="${input_tokens}/${window_size}"
if [ "$output_tokens" != "0" ] && [ "$output_tokens" != "null" ]; then
  token_usage="${token_usage} (+${output_tokens} out)"
fi

dir_label="${cwd##*/}"
if [ -n "$worktree_name" ]; then
  dir_label="${dir_label} @${worktree_name}"
fi

printf "\033[36mModel:\033[0m %s  \033[35mContext:\033[0m %s (%s)\n" "$model_label" "$token_usage" "$percent_label"
printf "\033[90m[%s] used %s%% | remaining %s%% | %s\033[0m\n" "$bar" "$used_int" "$remaining_int" "$dir_label"
