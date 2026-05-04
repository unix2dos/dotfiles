#!/bin/bash
# ============================================
# 网络上下行速度显示 (macOS) - RunCat 风格
# ============================================
# 用法: ./net_speed.sh
# 输出形如: 🌊 ↓ 234K ↑  12K   (定宽 14 字符，状态栏不抖动)
#
# 图标按"两个方向最大速度"分档：
#   < 10 KB/s   💤 idle
#   < 500 KB/s  🌊 browsing
#   < 5  MB/s   🚀 downloading
#   ≥ 5  MB/s   ⚡ heavy
# ============================================
# 原理:
#   1. 用 `route get default` 找当前默认网卡
#   2. 用 `netstat -ibn` 读累计字节数 (Ibytes / Obytes)
#   3. 把上一次采样写到 /tmp/.tmux_net_speed_<iface>，下一次算差值
#   4. 按 tmux status-interval 自然形成采样窗口
# ============================================

set -u

IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
IFACE="${IFACE:-en0}"

STATE="/tmp/.tmux_net_speed_${IFACE}"

read -r RX TX < <(netstat -ibn 2>/dev/null \
    | awk -v i="$IFACE" '$1==i && $3 ~ /^<Link/ {print $7, $10; exit}')

NOW=$(date +%s)

# 把字节数格式化为定宽 4 字符 (右对齐)：999B / 9.9K / 999K / 9.9M / 999M / 9.9G
human4() {
    local n=$1
    if   (( n < 1024 ));            then printf '%3dB' "$n"
    elif (( n < 10*1024 ));         then printf '%.1fK' "$(echo "scale=1; $n/1024" | bc)"
    elif (( n < 1024*1024 ));       then printf '%3dK' "$(( n / 1024 ))"
    elif (( n < 10*1024*1024 ));    then printf '%.1fM' "$(echo "scale=1; $n/1048576" | bc)"
    elif (( n < 1024*1024*1024 )); then printf '%3dM' "$(( n / 1048576 ))"
    else                                 printf '%.1fG' "$(echo "scale=1; $n/1073741824" | bc)"
    fi
}

# 按"两方向最大值"挑分档：返回 "图标 bg fg"
# 颜色经过挑选，跟 gpakosz 主题的圆角分隔符尽量协调
style_for() {
    local n=$1
    if   (( n <  10 * 1024 ));      then echo "💤 #3a3a3a #8a8a8a"   # 闲：暗灰，低对比，不抢眼
    elif (( n < 500 * 1024 ));      then echo "🌊 #005f87 #ffffff"   # 浏览：深蓝
    elif (( n <   5 * 1024*1024 )); then echo "🚀 #d78700 #000000"   # 下载：橙色 + 黑字
    else                                 echo "⚡ #d70000 #ffffff"   # 大流量：红
    fi
}

# 异常 / 首次：占位但保持定宽 + 用 idle 颜色
IDLE_BG="#3a3a3a"; IDLE_FG="#8a8a8a"
if [[ -z "${RX:-}" || -z "${TX:-}" ]]; then
    printf '#[bg=%s,fg=%s] 💤 ↓   -- ↑   -- #[default]\n' "$IDLE_BG" "$IDLE_FG"
    exit 0
fi

if [[ ! -f "$STATE" ]]; then
    echo "$NOW $RX $TX" > "$STATE"
    printf '#[bg=%s,fg=%s] 💤 ↓   0B ↑   0B #[default]\n' "$IDLE_BG" "$IDLE_FG"
    exit 0
fi

read -r LAST_T LAST_RX LAST_TX < "$STATE"
echo "$NOW $RX $TX" > "$STATE"

DT=$(( NOW - LAST_T ))
(( DT < 1 )) && DT=1

DRX=$(( RX - LAST_RX ))
DTX=$(( TX - LAST_TX ))
(( DRX < 0 )) && DRX=0
(( DTX < 0 )) && DTX=0

RX_BPS=$(( DRX / DT ))
TX_BPS=$(( DTX / DT ))

PEAK=$(( RX_BPS > TX_BPS ? RX_BPS : TX_BPS ))
read -r ICON BG FG <<< "$(style_for "$PEAK")"

# 输出形如 "#[bg=#005f87,fg=#ffffff]🌊 ↓ 234K ↑  12K#[default]"
# tmux 会解析 #[...] 颜色码；定宽 + 颜色档位双重传达"忙不忙"
printf '#[bg=%s,fg=%s] %s ↓ %4s ↑ %4s #[default]\n' \
    "$BG" "$FG" "$ICON" "$(human4 "$RX_BPS")" "$(human4 "$TX_BPS")"
