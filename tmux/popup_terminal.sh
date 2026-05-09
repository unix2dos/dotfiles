#!/usr/bin/env bash
# Toggle a persistent popup session and route it to the caller's pane directory.

set -euo pipefail

popup_session="_popup"
max_windows="${TMUX_POPUP_MAX_WINDOWS:-5}"
popup_title=" 🚀 Popup Terminal "
popup_style="fg=#00afff"

current_session="$(tmux display-message -p '#S')"
source_path="$(tmux display-message -p '#{pane_current_path}')"

is_shell_command() {
  case "$1" in
    bash|zsh|fish|sh|*/bash|*/zsh|*/fish|*/sh) return 0 ;;
    *) return 1 ;;
  esac
}

open_popup() {
  tmux popup \
    -w 90% \
    -h 90% \
    -b heavy \
    -S "$popup_style" \
    -T "$popup_title" \
    -E "tmux attach-session -t $popup_session"
}

touch_window() {
  local window_id="$1"
  tmux set-option -w -q -t "$window_id" @popup_last_used "$(date +%s)"
}

refresh_shell_window() {
  local window_id="$1"
  local command

  command="$(tmux display-message -p -t "$window_id" '#{pane_current_command}')"
  if ! is_shell_command "$command"; then
    return 0
  fi

  tmux send-keys -t "$window_id" C-l "git status" Enter
}

find_window_for_path() {
  local window_id window_path

  tmux list-windows -t "$popup_session" -F '#{window_id}	#{pane_current_path}' |
    while IFS=$'\t' read -r window_id window_path; do
      if [[ "$window_path" == "$source_path" ]]; then
        printf '%s\n' "$window_id"
        return 0
      fi
    done
}

trim_old_shell_window_if_needed() {
  local count window_id last_used command active

  count="$(tmux list-windows -t "$popup_session" -F '#{window_id}' | wc -l | tr -d ' ')"
  if (( count < max_windows )); then
    return 0
  fi

  while IFS=$'\t' read -r _ window_id command active; do
    if [[ "$active" == "1" ]]; then
      continue
    fi
    if ! is_shell_command "$command"; then
      continue
    fi

    tmux kill-window -t "$window_id"
    return 0
  done < <(
    while IFS= read -r window_id; do
      last_used="$(tmux show-options -wqv -t "$window_id" @popup_last_used || true)"
      command="$(tmux display-message -p -t "$window_id" '#{pane_current_command}')"
      active="$(tmux display-message -p -t "$window_id" '#{window_active}')"
      printf '%s\t%s\t%s\t%s\n' "${last_used:-0}" "$window_id" "$command" "$active"
    done < <(tmux list-windows -t "$popup_session" -F '#{window_id}') |
      sort -n
  )
}

select_or_create_window_for_source_path() {
  local window_id window_name

  window_id="$(find_window_for_path | head -n 1)"
  if [[ -n "$window_id" ]]; then
    tmux select-window -t "$window_id"
    touch_window "$window_id"
    refresh_shell_window "$window_id"
    return 0
  fi

  trim_old_shell_window_if_needed

  window_name="$(basename "$source_path")"
  window_id="$(tmux new-window -d -P -F '#{window_id}' -t "$popup_session:" -c "$source_path" -n "$window_name")"
  touch_window "$window_id"
  refresh_shell_window "$window_id"
  tmux select-window -t "$window_id"
}

if [[ "$current_session" == "$popup_session" ]]; then
  tmux detach-client
  exit 0
fi

if tmux has-session -t "$popup_session" 2>/dev/null; then
  select_or_create_window_for_source_path
  open_popup
else
  first_window="$(tmux new-session -d -P -F '#{window_id}' -s "$popup_session" -c "$source_path" -n "$(basename "$source_path")")"
  touch_window "$first_window"
  refresh_shell_window "$first_window"
  open_popup
fi
