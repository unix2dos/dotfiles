#!/usr/bin/env bash
# 通过本机 `opencode run` 用 opencode-go 订阅快速总结指定 tmux pane 当前内容
# 用法:
#   ai_pane_summary.sh <pane_target>            # 同步总结
#   ai_pane_summary.sh --preview <pane_target>  # 非阻塞预览，缓存未就绪时后台预热
#   ai_pane_summary.sh --prewarm [pane_target...] # 后台预热多个 pane
#   ai_pane_summary.sh --cached-summary <pane_target> # 单行缓存摘要，未就绪则后台预热
#   ai_pane_summary.sh --raw-preview <pane_target> # 原始内容预览，去掉开头空行
# 输出: "🤖 AI 总结 ... \n\n📺 原始内容 ..."
# 注: 按 pane 缓存，避免重复调用 opencode；--refresh 会强制更新当前 pane 缓存。
#      列表模式只在打开时懒刷新过期/内容变化的缓存，不做常驻后台轮询。
#      失败时错误会写入缓存目录的 .error 文件，并显示在 SUMMARY 列。

set -u

mode="show"
case "${1:-}" in
  --preview|--prewarm|--cached-summary|--raw-preview)
    mode="${1#--}"
    shift
    ;;
  --refresh)
    mode="refresh"
    shift
    ;;
esac

if [ "$mode" != "prewarm" ] && [ -z "${1:-}" ]; then
  echo "usage: $0 [--preview|--refresh] <pane_target>" >&2
  exit 1
fi

cache_dir="${TMPDIR:-/tmp}/ai_pane_summary_cache"
mkdir -p "$cache_dir"
summary_model="${AI_PANE_SUMMARY_MODEL:-opencode-go/mimo-v2.5}"
request_timeout="${AI_PANE_SUMMARY_TIMEOUT:-30}"
capture_lines="${AI_PANE_SUMMARY_LINES:-160}"
max_input_chars="${AI_PANE_SUMMARY_MAX_CHARS:-12000}"
list_summary_chars="${AI_PANE_SUMMARY_LIST_CHARS:-80}"
lock_ttl="${AI_PANE_SUMMARY_LOCK_TTL:-}"
summary_ttl="${AI_PANE_SUMMARY_TTL:-300}"
case "$request_timeout" in
  ''|*[!0-9]*) request_timeout=12 ;;
esac
if [ -z "$lock_ttl" ]; then
  lock_ttl=$((request_timeout + 5))
fi
case "$lock_ttl" in
  ''|*[!0-9]*) lock_ttl=17 ;;
esac
case "$summary_ttl" in
  ''|*[!0-9]*) summary_ttl=300 ;;
esac
system_prompt="你是一个终端 pane 状态摘要器。用简洁中文输出 1-2 句，直接说这个 pane 当前正在做什么、是否有阻塞/报错。不要前缀，不要解释。"

capture_plain() {
  local target="$1"
  tmux capture-pane -p -S - -t "$target" 2>/dev/null | tail -n "$capture_lines" | head -c "$max_input_chars" || true
}

cache_path_for() {
  local target="$1"
  local pane_id hash
  pane_id=$(tmux display-message -p -t "$target" '#{pane_id}' 2>/dev/null || printf '%s' "$target")
  hash=$(printf '%s' "$pane_id" | shasum | awk '{print $1}')
  printf '%s/%s' "$cache_dir" "$hash"
}

content_hash() {
  printf '%s' "$1" | shasum | awk '{print $1}'
}

cache_epoch() {
  local cache_file="$1"

  stat -f '%m' "$cache_file" 2>/dev/null || stat -c '%Y' "$cache_file" 2>/dev/null || printf '0'
}

lock_is_stale() {
  local lock_dir="$1"
  local epoch now age pid

  [ -d "$lock_dir" ] || return 1
  pid=$(cat "${lock_dir}/pid" 2>/dev/null || true)
  case "$pid" in
    ''|*[!0-9]*) ;;
    *) kill -0 "$pid" 2>/dev/null || return 0 ;;
  esac
  [ "$lock_ttl" -gt 0 ] || return 0

  epoch=$(cache_epoch "$lock_dir")
  now=$(date '+%s')
  age=$((now - epoch))
  [ "$age" -gt "$lock_ttl" ]
}

reclaim_stale_lock() {
  local lock_dir="$1"

  lock_is_stale "$lock_dir" || return 1
  rm -f "${lock_dir}/pid" "${lock_dir}/started_at" 2>/dev/null || true
  rmdir "$lock_dir" 2>/dev/null
}

acquire_lock() {
  local lock_dir="$1"

  if mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "${lock_dir}/pid" 2>/dev/null || true
    date '+%s' > "${lock_dir}/started_at" 2>/dev/null || true
    return 0
  fi

  if reclaim_stale_lock "$lock_dir" && mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "${lock_dir}/pid" 2>/dev/null || true
    date '+%s' > "${lock_dir}/started_at" 2>/dev/null || true
    return 0
  fi

  return 1
}

meta_value() {
  local cache_file="$1"
  local key="$2"
  local meta_file="${cache_file}.meta"

  [ -s "$meta_file" ] || return 0
  awk -F '=' -v key="$key" '$1 == key {print substr($0, index($0, "=") + 1); exit}' "$meta_file"
}

write_cache() {
  local cache_file="$1"
  local summary="$2"
  local plain="$3"

  printf '%s' "$summary" > "$cache_file"
  {
    printf 'content_hash=%s\n' "$(content_hash "$plain")"
    printf 'summarized_at=%s\n' "$(date '+%s')"
  } > "${cache_file}.meta"
}

cache_is_fresh() {
  local cache_file="$1"
  local _plain="$2"
  local summarized_at now age

  [ -s "$cache_file" ] || return 1
  [ "$summary_ttl" -gt 0 ] || return 1

  summarized_at=$(meta_value "$cache_file" "summarized_at")
  case "$summarized_at" in
    ''|*[!0-9]*) summarized_at=$(cache_epoch "$cache_file") ;;
  esac

  now=$(date '+%s')
  age=$((now - summarized_at))
  [ "$age" -le "$summary_ttl" ]
}

warm_one() {
  local target="$1"
  local force="${2:-0}"
  local plain cache_file lock_dir summary status
  plain=$(capture_plain "$target")
  [ -n "$plain" ] || return 0

  cache_file=$(cache_path_for "$target")
  if [ "$force" != "1" ] && cache_is_fresh "$cache_file" "$plain"; then
    return 0
  fi

  lock_dir="${cache_file}.lock"
  if acquire_lock "$lock_dir"; then
    status=0
    summary=$(summarize_with_opencode "$plain") || status=$?
    if [ "$status" -eq 0 ] && [ -n "$summary" ]; then
      write_cache "$cache_file" "$summary" "$plain"
      rm -f "${cache_file}.error" 2>/dev/null || true
    else
      [ -n "$summary" ] || summary="opencode 调用失败但未输出错误信息"
      printf '%s' "$summary" > "${cache_file}.error"
    fi
    rm -f "${lock_dir}/pid" "${lock_dir}/started_at" 2>/dev/null || true
    rmdir "$lock_dir" 2>/dev/null || true
  else
    wait_for_cache "$cache_file"
  fi
}

summarize_with_opencode() {
  local plain="$1"
  local prompt output status summary

  if ! command -v opencode >/dev/null 2>&1; then
    printf '找不到 opencode，无法调用 opencode-go 订阅。请确认 PATH。'
    return 1
  fi

  prompt=$(printf '%s\n\n终端内容:\n---\n%s\n---' "$system_prompt" "$plain")

  status=0
  output=$(perl -e 'alarm shift; exec @ARGV' "$request_timeout" \
    opencode run --pure -m "$summary_model" "$prompt" 2>&1) || status=$?

  if [ "$status" -ne 0 ]; then
    if [ "$status" -eq 142 ] || [ "$status" -eq 14 ]; then
      printf 'opencode 调用超时 (>%ss)' "$request_timeout"
    else
      printf 'opencode run 失败 (exit %s): %s' "$status" "$(printf '%s' "$output" | tr '\n' ' ' | head -c 200)"
    fi
    return 1
  fi

  # 去掉 ANSI 转义、`> agent · model` 头部和前导空行
  summary=$(printf '%s\n' "$output" \
    | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g' \
    | awk '
        !started && /^[[:space:]]*$/ { next }
        !started && /^>/ { next }
        { started = 1; print }
      ' \
    | awk 'NF {p=1} p {lines[NR]=$0; last=NR} END {for (i=1;i<=last;i++) print lines[i]}')

  if [ -z "$summary" ]; then
    printf 'opencode 返回为空 (raw: %s)' "$(printf '%s' "$output" | tr '\n' ' ' | head -c 200)"
    return 1
  fi
  printf '%s' "$summary"
}

wait_for_cache() {
  local cache_file="$1"
  local lock_dir="${cache_file}.lock"
  local waited=0

  while [ -d "$lock_dir" ] && [ "$waited" -lt 300 ]; do
    reclaim_stale_lock "$lock_dir" && break
    sleep 0.1
    waited=$((waited + 1))
  done
}

cache_time_label() {
  local cache_file="$1"
  local epoch

  epoch=$(meta_value "$cache_file" "summarized_at")
  case "$epoch" in
    ''|*[!0-9]*) epoch=$(cache_epoch "$cache_file") ;;
  esac

  if [ -z "$epoch" ] || [ "$epoch" = "0" ]; then
    printf '--:--'
    return 0
  fi

  date -r "$epoch" '+%H:%M' 2>/dev/null || date -d "@$epoch" '+%H:%M' 2>/dev/null || printf '--:--'
}

preview_one() {
  local target="$1"
  local raw plain cache_file summary
  raw=$(tmux capture-pane -e -p -t "$target" 2>/dev/null || true)
  plain=$(capture_plain "$target")
  cache_file=$(cache_path_for "$target")

  if [ -s "$cache_file" ]; then
    if ! cache_is_fresh "$cache_file" "$plain"; then
      ( warm_one "$target" ) >/dev/null 2>&1 &
    fi
    summary=$(cat "$cache_file")
    printf '═══ 🤖 AI 总结 ═══\n%s\n\n═══ 📺 原始内容 ═══\n%s\n' "$summary" "$raw"
  else
    ( warm_one "$target" ) >/dev/null 2>&1 &
    printf '⏳ 正在通过 opencode (%s) 快速总结，缓存就绪后会瞬间显示。按 ? 可等待本 pane 总结完成。\n\n═══ 📺 原始内容 ═══\n%s\n' "$summary_model" "$raw"
  fi
}

show_one() {
  local target="$1"
  local raw plain cache_file summary
  raw=$(tmux capture-pane -e -p -t "$target" 2>/dev/null || true)
  plain=$(capture_plain "$target")
  cache_file=$(cache_path_for "$target")

  if ! cache_is_fresh "$cache_file" "$plain"; then
    printf '⏳ 调用 opencode (%s) 快速总结中，请稍候...\n\n' "$summary_model"
    warm_one "$target"
    wait_for_cache "$cache_file"
  fi

  summary=$(cat "$cache_file" 2>/dev/null || true)
  if [ -z "$summary" ]; then
    if [ -s "${cache_file}.error" ]; then
      summary="❌ $(cat "${cache_file}.error")"
    else
      summary="opencode 总结不可用。请确认 \`opencode\` 已安装且 opencode-go 订阅可用 (opencode auth 检查)。"
    fi
  fi
  printf '═══ 🤖 AI 总结 ═══\n%s\n\n═══ 📺 原始内容 ═══\n%s\n' "$summary" "$raw"
}

refresh_one() {
  local target="$1"
  local cache_file summary error_file
  cache_file=$(cache_path_for "$target")
  error_file="${cache_file}.error"
  rm -f "$error_file" 2>/dev/null || true

  warm_one "$target" 1
  wait_for_cache "$cache_file"

  if [ -s "$error_file" ]; then
    cat "$error_file"
    return 1
  fi

  summary=$(cat "$cache_file" 2>/dev/null || true)
  if [ -z "$summary" ]; then
    summary="opencode 总结不可用。请确认 \`opencode\` 已安装且 opencode-go 订阅可用 (opencode auth 检查)。"
  fi
  printf '%s' "$summary"
}

cached_summary_one() {
  local target="$1"
  local cache_file error_file summary summarized_at label err
  cache_file=$(cache_path_for "$target")
  error_file="${cache_file}.error"

  # 错误优先：refresh 失败时立刻在 SUMMARY 列暴露原因，不再静默
  if [ -s "$error_file" ] && { [ ! -s "$cache_file" ] || [ "$error_file" -nt "$cache_file" ]; }; then
    err=$(tr '\n\t' '  ' < "$error_file" | tr -s ' ' | cut -c "1-${list_summary_chars}")
    printf '❌ %s' "$err"
    return 0
  fi

  if [ -s "$cache_file" ]; then
    label=""
    if ! cache_is_fresh "$cache_file" ""; then
      label="stale "
    fi
    summary=$(cat "$cache_file")
    summarized_at=$(cache_time_label "$cache_file")
    summary=$(printf '%s' "$summary" | tr '\n\t' '  ' | tr -s ' ' | cut -c "1-${list_summary_chars}")
    printf '[%s%s] %s' "$label" "$summarized_at" "$summary"
  else
    printf '…'
  fi
}

raw_preview_one() {
  local target="$1"
  tmux capture-pane -e -p -t "$target" 2>/dev/null | awk 'seen || /[^[:space:]]/ {seen=1; print}'
}

prewarm_many() {
  local targets=("$@")
  local target running max_jobs
  max_jobs="${AI_PANE_SUMMARY_JOBS:-4}"

  if [ "${#targets[@]}" -eq 0 ]; then
    while IFS= read -r target; do
      [ -n "$target" ] && targets+=("$target")
    done
  fi

  for target in "${targets[@]}"; do
    ( warm_one "$target" ) >/dev/null 2>&1 &
    while :; do
      running=$(jobs -rp | wc -l | tr -d ' ')
      [ "$running" -lt "$max_jobs" ] && break
      sleep 0.1
    done
  done

  wait
}

case "$mode" in
  preview) preview_one "$1" ;;
  prewarm) prewarm_many "$@" ;;
  cached-summary) cached_summary_one "$1" ;;
  raw-preview) raw_preview_one "$1" ;;
  refresh) refresh_one "$1" ;;
  *) show_one "$1" ;;
esac
