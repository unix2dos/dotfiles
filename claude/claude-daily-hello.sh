#!/bin/bash
# claude code 每日定时唤醒脚本
# 由 cron 每天 09:00 / 14:00 / 19:00 各执行一次

export PATH="/Users/liuwei/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_DIR="$HOME/.local/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/claude-daily.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') claude daily hello started" >> "$LOG_FILE"

cd "$HOME/workspace/dotfiles" && \
  claude --model haiku -p "hello" >> "$LOG_FILE" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') claude daily hello finished" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
