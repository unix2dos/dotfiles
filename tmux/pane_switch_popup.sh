#!/usr/bin/env bash
# M-w global pane switcher.
#
# Lists all panes in an fzf popup with a live capture preview, then switches to
# the selected pane. If invoked from the _popup popup client, it detaches first
# so the target pane becomes visible.

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

current_pane=$(tmux display-message -p '#{pane_id}')

# Border styling (same logic as plugin)
border_styling=""
fzf_version=$(fzf --version | awk '{print $1}')

vercomp '0.58.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --input-border --input-label=' Search ' --info=inline-right"
  border_styling+=" --list-border --list-label=' 📋 All Panes '"
  border_styling+=" --preview-border --preview-label=' Preview '"
fi

vercomp '0.61.0' "${fzf_version}"
if [[ $? -ne 1 ]]; then
  border_styling+=" --ghost 'type to search...'"
fi

if [[ -z "${border_styling}" ]]; then
  border_styling="--preview-label='pane preview'"
fi

# Preview command (same as plugin)
preview="--preview 'tmux capture-pane -ep -S -\$(( \${FZF_PREVIEW_LINES:-30} )) -t {1} | awk \"{a[NR]=\\\$0} END{for(i=NR;i>0;i--) if(a[i]~/[^ \\t]/){for(j=1;j<=i;j++) print a[j]; exit}}\" | tail -n \$(( \${FZF_PREVIEW_LINES:-30} ))' --preview-window=right,,,nowrap"

# Run fzf WITHOUT --tmux (runs directly in the display-popup terminal)
pane=$(tmux list-panes -aF "#{pane_id} #{s/%//:pane_id} #{session_name} #{window_name}" | \
  eval fzf --exit-0 --print-query --reverse --with-nth=2.. \
    --bind "'alt-w:abort'" \
    "${border_styling}" "${preview}" | \
  tail -1)

pane_id=$(echo "${pane}" | awk '{print $1}')

if [[ -z "${pane_id}" ]]; then
  tmux switch-client -t "${current_pane}"
elif tmux has-session -t "${pane_id}" 2>/dev/null; then
  client_flags="$(tmux display-message -p '#{client_flags}')"
  # 如果从 popup 浮窗 client 切到外部 pane，先 detach 让目标 pane 可见。
  # 如果是直接 attach 到 _popup 的一级 session，则不 detach，直接 switch-client。
  if [[ "$(tmux display-message -p '#S')" == "_popup" && "$client_flags" == *active-pane* && "$client_flags" == *ignore-size* ]]; then
    tmux detach-client -E true
    sleep 0.1
  fi
  tmux switch-client -t "${pane_id}"
else
  tmux command-prompt -b -p "Press ENTER to create a new window in the current session [${pane}]" "new-window -n \"${pane}\""
fi
