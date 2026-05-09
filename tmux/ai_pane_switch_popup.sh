#!/usr/bin/env bash
# 快速切换 AI CLI pane（支持 display-popup toggle）

vercomp() {
  local v1="$1" v2="$2"
  IFS='.' read -r -a ver1 <<< "$v1"
  IFS='.' read -r -a ver2 <<< "$v2"
  for i in 0 1 2; do
    local num1="${ver1[i]:-0}" num2="${ver2[i]:-0}"
    if (( num1 > num2 )); then return 1
    elif (( num1 < num2 )); then return 2; fi
  done
  return 0
}

# Border styling（与 pane_switch_popup.sh 统一）
border_styling=""
fzf_version=$(fzf --version | awk '{print $1}')

vercomp '0.58.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --input-border --input-label=' Search ' --info=inline-right"
  border_styling+=" --list-border --list-label=' 🤖 AI Panes '"
  border_styling+=" --preview-border --preview-label=' Preview '"
fi

vercomp '0.61.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --ghost 'type to search...'"
fi

if [[ -z "${border_styling}" ]]; then
  border_styling="--preview-label='pane preview'"
fi

# 收集 AI CLI pane
tmpf=$(mktemp)
tmux list-panes -a -F "#{pane_pid} #{session_name}:#{window_index}.#{pane_index} #{pane_current_path} #{pane_title}" > "$tmpf"

results=""
for cpid in $(ps -eo pid,command | /usr/bin/grep -E "^[[:space:]]*[0-9]+ (\S*/)?(claude|codex|gemini|amp|agent|droid)([[:space:]]|$)" | /usr/bin/grep -v grep | awk '{print $1}' | sort -rn); do
  cmd=$(ps -o command= -p "$cpid" 2>/dev/null | sed 's/^ *//')
  cmd=$(basename "$(echo "$cmd" | awk '{print $1}')")
  pid=$cpid
  while [ "$pid" != "1" ] && [ -n "$pid" ]; do
    line=$(/usr/bin/grep -m1 "^${pid} " "$tmpf")
    if [ -n "$line" ]; then
      label=$(echo "$line" | awk '{print $2}')
      dir=$(basename "$(echo "$line" | awk '{print $3}')")
      results="${results}$(printf "%-20s %-10s %s" "$dir" "$cmd" "$label")\n"
      break
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d " ")
  done
done
rm -f "$tmpf"

if [ -z "$results" ]; then
  echo "No AI CLI found."
  read -r
  exit 0
fi

# fzf 选择
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
summary_cmd="${script_dir}/ai_pane_summary.sh {-1}"
raw_cmd='tmux capture-pane -e -p -t {-1}'

header_line=$(printf "%-20s %-10s %s" "DIR" "CLI" "PANE")
header_hint='?: AI 总结  |  /: 还原原始'

selected=$(printf "$results" | \
  eval fzf --exit-0 --reverse --no-sort \
    --bind "'alt-q:abort'" \
    --bind "'?:change-preview(${summary_cmd})+change-preview-label( 🤖 AI Summary )'" \
    --bind "'/:change-preview(${raw_cmd})+change-preview-label( Preview )'" \
    --header="'${header_line}
${header_hint}'" \
    --preview="'${raw_cmd}'" \
    --preview-window=right:60%,nowrap \
    "${border_styling}")

if [ -n "$selected" ]; then
  target=$(echo "$selected" | awk '{print $NF}')
  # 如果在 _popup session 内，先 detach 退出 popup，再切换
  if [[ "$(tmux display-message -p '#S')" == "_popup" ]]; then
    tmux detach-client
    sleep 0.1
  fi
  tmux switch-client -t "$target"
fi
