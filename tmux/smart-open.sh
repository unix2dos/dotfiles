#!/usr/bin/env bash
# ============================================
# tmux Cmd+O 智能 open
# ============================================
# 由 .tmux.conf.local 中 user-keys + bind-key -n User0 调用
# 行为：
#   1. 剪贴板里若是合法路径(支持 ~ 展开和 file:// 前缀) → open 该路径
#   2. 否则 → open 传入的 pane_current_path
# 用法: smart-open.sh "<pane_current_path>"
# ============================================

set -u

pane_path="${1:-$HOME}"

# 仅在 macOS（有 open 和 pbpaste）时工作
if ! command -v open >/dev/null 2>&1; then
    exit 0
fi

target=""

if command -v pbpaste >/dev/null 2>&1; then
    # 限长，防剪贴板过大
    clip="$(pbpaste 2>/dev/null | head -c 4096)"
    # 去首尾空白和换行
    clip="${clip#"${clip%%[![:space:]]*}"}"
    clip="${clip%"${clip##*[![:space:]]}"}"
    # 去 file:// 前缀
    clip="${clip#file://}"
    # 展开 ~
    case "$clip" in
        "~"|"~/"*) clip="${HOME}${clip#\~}" ;;
    esac

    if [ -n "$clip" ] && [ -e "$clip" ]; then
        target="$clip"
    fi
fi

if [ -z "$target" ]; then
    open "$pane_path" >/dev/null 2>&1
elif [ -d "$target" ]; then
    # 目录：在 Finder 里打开
    open "$target" >/dev/null 2>&1
else
    # 普通文件：在 Finder 里"显示"，避免执行 .app / 挂载 .dmg / 安装 .pkg
    open -R "$target" >/dev/null 2>&1
fi
