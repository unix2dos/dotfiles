#!/bin/bash
# 根据当前时间，用 pmset 调度下一个唤醒时刻
# 唤醒时刻: 09:00, 14:00, 16:00, 19:00

# 提前1分钟唤醒，确保 cron 整点触发时系统已就绪
WAKE_TIMES=("08:59" "13:59" "15:59" "18:59")
NOW=$(date +%H:%M)
TODAY=$(date +%m/%d/%Y)
TOMORROW=$(date -v+1d +%m/%d/%Y)

NEXT_DATE="$TOMORROW"
NEXT_TIME="${WAKE_TIMES[0]}"

for t in "${WAKE_TIMES[@]}"; do
    if [[ "$t" > "$NOW" ]]; then
        NEXT_DATE="$TODAY"
        NEXT_TIME="$t"
        break
    fi
done

sudo pmset schedule wake "$NEXT_DATE $NEXT_TIME:00"

LOG_DIR="$HOME/.local/log"
mkdir -p "$LOG_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') scheduled next wake: $NEXT_DATE $NEXT_TIME:00" >> "$LOG_DIR/wake-schedule.log"
