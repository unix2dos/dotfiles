#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

cwd="$(echo "$payload" | jq -r '.workspace.current_dir // .cwd // ""')"
dir_name="$(basename "$cwd")"

model="$(echo "$payload" | jq -r '.model.display_name // .model.id // "unknown-model"')"
ctx_used_raw="$(echo "$payload" | jq -r '.context_window.used_percentage // 0')"
ctx_rem_raw="$(echo "$payload" | jq -r '.context_window.remaining_percentage // 0')"

to_int() {
  local n="$1"
  printf "%.0f" "$n" 2>/dev/null || echo "0"
}

ctx_used="$(to_int "$ctx_used_raw")"
ctx_rem="$(to_int "$ctx_rem_raw")"

wt_name="$(echo "$payload" | jq -r '.worktree.name // ""')"
if [[ "$wt_name" == "null" ]]; then
  wt_name=""
fi

branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
  if [[ -z "$wt_name" ]]; then
    wt_name="$(basename "$cwd")"
  fi
fi

bar_width=20
filled=$((ctx_used * bar_width / 100))
if (( filled < 0 )); then
  filled=0
fi
if (( filled > bar_width )); then
  filled=$bar_width
fi
empty=$((bar_width - filled))

fill="$(printf '%*s' "$filled" '' | tr ' ' '=')"
pad="$(printf '%*s' "$empty" '' | tr ' ' '-')"

CLR_RESET=$'\033[0m'
CLR_DIM=$'\033[2m'
CLR_CYAN=$'\033[36m'
CLR_BLUE=$'\033[34m'
CLR_GREEN=$'\033[32m'
CLR_YELLOW=$'\033[33m'
CLR_MAGENTA=$'\033[35m'
CLR_GRAY=$'\033[90m'

ctx_color="$CLR_GREEN"
if (( ctx_used >= 70 )); then
  ctx_color="$CLR_YELLOW"
fi
if (( ctx_used >= 90 )); then
  ctx_color="$CLR_MAGENTA"
fi

line1="${CLR_CYAN}📁 ${dir_name}${CLR_RESET}"
if [[ -n "$branch" ]]; then
  line1+=" ${CLR_BLUE}🌿 ${branch}${CLR_RESET}"
fi
if [[ -n "$wt_name" ]]; then
  line1+=" ${CLR_GRAY}│ 🧩 ${wt_name}${CLR_RESET}"
fi

line2="${CLR_DIM}🤖${CLR_RESET} ${CLR_GREEN}${model}${CLR_RESET} ${CLR_GRAY}│${CLR_RESET} "
line2+="${CLR_DIM}🧠${CLR_RESET} ${ctx_color}${fill}${CLR_GRAY}${pad}${CLR_RESET} "
line2+="${ctx_color}${ctx_used}%${CLR_RESET} ${CLR_GRAY}(♻️ ${ctx_rem}% left)${CLR_RESET}"

printf "%b\n%b\n" "$line1" "$line2"
