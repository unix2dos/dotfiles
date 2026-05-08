#!/usr/bin/env bash
# 用 amp 总结指定 tmux pane 当前内容
# 用法: ai_pane_summary.sh <pane_target>
# 输出: "🤖 AI 总结 ... \n\n📺 原始内容 ..."
# 注: 按内容 hash 缓存，避免重复调用 amp

set -u
target="${1:-}"
if [ -z "$target" ]; then
  echo "usage: $0 <pane_target>" >&2
  exit 1
fi

cache_dir="${TMPDIR:-/tmp}/ai_pane_summary_cache"
mkdir -p "$cache_dir"

raw=$(tmux capture-pane -e -p -t "$target" 2>/dev/null || true)
plain=$(tmux capture-pane -p -t "$target" 2>/dev/null || true)

hash=$(printf '%s' "$plain" | shasum | awk '{print $1}')
cache_file="$cache_dir/$hash"

if [ -s "$cache_file" ]; then
  summary=$(cat "$cache_file")
else
  printf '⏳ 调用 amp 总结中，请稍候 (5-15s)...\n\n'
  summary=$(printf '%s' "$plain" | amp -x "用 1-2 句简洁中文总结这个终端 pane 当前正在做什么，直接输出结论，不要解释、不要前缀" 2>&1)
  if [ -n "$summary" ]; then
    printf '%s' "$summary" > "$cache_file"
  fi
fi

printf '═══ 🤖 AI 总结 ═══\n%s\n\n═══ 📺 原始内容 ═══\n%s\n' "$summary" "$raw"
