#!/usr/bin/env bash
# M-q AI CLI pane switcher.
#
# Finds panes running AI CLIs such as claude/codex/gemini/amp/agent/droid,
# shows them in an fzf popup, and switches to the selected pane. Preview
# content is provided by ai_pane_summary.sh; M-r refreshes, M-t toggles preview.

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
preview_label=" Preview "

vercomp '0.58.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --input-border --input-label=' Search ' --info=inline-right"
  border_styling+=" --list-border"
  border_styling+=" --preview-border --preview-label='${preview_label}'"
fi

vercomp '0.61.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --ghost 'type to search...'"
fi

if [[ -z "${border_styling}" ]]; then
  border_styling="--preview-label='pane preview'"
fi

# 收集 AI CLI pane
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

collect_results() {
  local tmpf results cpid cmd pid line label dir summary row
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
        summary=$("${script_dir}/ai_pane_summary.sh" --cached-summary "$label")
        printf -v row '%s\t%s\t%s\t%s' "$dir" "$cmd" "$label" "$summary"
        results="${results}${row}"$'\n'
        break
      fi
      pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d " ")
    done
  done
  rm -f "$tmpf"
  printf '%s' "$results"
}

format_header() {
  printf '%-10s  %-8s  %-18s  %s\t%s\n' "DIR" "CLI" "PANE" "SUMMARY" "__pane"
}

format_results() {
  awk -F '\t' '
    function fit(s, w) {
      return length(s) > w ? substr(s, 1, w - 1) "~" : s
    }
    {
      summary = $4
      for (i = 5; i <= NF; i++) {
        summary = summary " " $i
      }
      printf "%-10s  %-8s  %-18s  %s\t%s\n", fit($1, 10), fit($2, 8), fit($3, 18), summary, $3
    }
  '
}

case "${1:-}" in
  --list)
    collect_results
    exit 0
    ;;
  --list-with-header)
    format_header
    collect_results | format_results
    exit 0
    ;;
esac

results=$(collect_results)

if [ -z "$results" ]; then
  echo "No AI CLI found."
  read -r
  exit 0
fi

# fzf 选择
summary_cmd="${script_dir}/ai_pane_summary.sh --refresh {2}"
raw_cmd="${script_dir}/ai_pane_summary.sh --raw-preview {2}"
reload_cmd="${script_dir}/ai_pane_switch_popup.sh --list-with-header"
refresh_reload_cmd="${summary_cmd} >/dev/null; ${reload_cmd}"

printf '%s' "$results" | awk -F '\t' '{print $3}' | "${script_dir}/ai_pane_summary.sh" --prewarm >/dev/null 2>&1 &

list_input=$(printf '%s' "$results" | { format_header; format_results; })

selected=$(printf '%s' "$list_input" | \
  eval fzf --exit-0 --reverse --no-sort \
    --delimiter="'	'" \
    --with-nth="'1'" \
    --header-lines=1 \
    --bind "'alt-q:abort'" \
    --bind "'alt-t:toggle-preview'" \
    --bind "'load:change-prompt(> )'" \
    --bind "'alt-r:change-prompt(刷新中> )+reload(${refresh_reload_cmd})+change-preview(${raw_cmd})'" \
    --preview="'${raw_cmd}'" \
    --preview-window=down:55%,nowrap \
    "${border_styling}")

if [ -n "$selected" ]; then
  target=$(echo "$selected" | awk -F '\t' '{print $2}')
  # 如果在 _popup session 内，先 detach 退出 popup，再切换
  if [[ "$(tmux display-message -p '#S')" == "_popup" ]]; then
    tmux detach-client
    sleep 0.1
  fi
  tmux switch-client -t "$target"
fi
