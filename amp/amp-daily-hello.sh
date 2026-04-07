#!/bin/bash
# amp 每日定时唤醒脚本
# 由 launchd 每天自动执行一次

export PATH="/Users/liuwei/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_DIR="$HOME/.local/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/amp-daily.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') amp daily hello started" >> "$LOG_FILE"

cd "$HOME/workspace/dotfiles" && amp -x "hello" >> "$LOG_FILE" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') amp daily hello finished" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
