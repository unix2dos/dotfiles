#!/bin/bash
# ============================================
# AI Kit — 项目级 AI 工具安装脚本
# Project-level AI tools installer
# ============================================
# 在项目目录下执行此脚本，自动检测已安装的 AI 工具并完成安装。
# Run in your project root. Auto-detects installed AI tools and installs accordingly.
#
# 用法 / Usage:
#   bash ~/workspace/dotfiles/ai-kit/install.sh
# ============================================

set -euo pipefail

# --- 颜色输出 / Color output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

info()  { echo -e "${GREEN}[ai-kit]${NC} $*"; }
warn()  { echo -e "${YELLOW}[ai-kit]${NC} $*"; }
skip()  { echo -e "${GRAY}[ai-kit] skip${NC} $*"; }

# --- 工具检测 / Tool detection ---
# 优先检测配置目录，兼顾命令检测
# Prefer config dir detection, fall back to command check

detect_claude()      { [ -d "$HOME/.claude" ] || command -v claude &>/dev/null; }
detect_cursor()      { [ -d "$HOME/.cursor" ] || command -v cursor &>/dev/null; }
detect_codex()       { [ -d "$HOME/.codex" ] || command -v codex &>/dev/null; }
detect_antigravity() { [ -d "$HOME/.gemini/antigravity" ] || command -v antigravity &>/dev/null; }

# --- uipro-cli 安装 / uipro-cli setup ---
ensure_uipro() {
  if command -v uipro &>/dev/null; then
    return 0
  fi
  info "Installing uipro-cli..."
  npm install -g uipro-cli
}

# --- ui-ux-pro-max-skill 安装 / Installation ---
install_ui_ux_pro_max() {
  local installed=()
  local skipped=()
  local manual=()

  ensure_uipro

  # Claude Code
  if detect_claude; then
    info "Installing ui-ux-pro-max → Claude Code..."
    uipro init --ai claude
    installed+=("Claude Code")
  else
    skip "Claude Code not detected"
    skipped+=("Claude Code")
  fi

  # Cursor
  if detect_cursor; then
    info "Installing ui-ux-pro-max → Cursor..."
    uipro init --ai cursor
    installed+=("Cursor")
  else
    skip "Cursor not detected"
    skipped+=("Cursor")
  fi

  # Codex
  if detect_codex; then
    info "Installing ui-ux-pro-max → Codex..."
    uipro init --ai codex
    installed+=("Codex")
  else
    skip "Codex not detected"
    skipped+=("Codex")
  fi

  # Antigravity
  if detect_antigravity; then
    info "Installing ui-ux-pro-max → Antigravity..."
    uipro init --ai antigravity
    installed+=("Antigravity")
  else
    skip "Antigravity not detected"
    skipped+=("Antigravity")
  fi

  # 手动安装提醒 / Manual install reminders
  manual+=("ed3d-plugins (Claude Code only)  → /plugin marketplace add https://github.com/ed3dai/ed3d-plugins.git")
  manual+=("claude-skills  (Claude Code only)  → /plugin marketplace add jeffallan/claude-skills")

  # --- 摘要 / Summary ---
  echo ""
  echo "========================================"
  echo "  AI Kit Install Summary"
  echo "========================================"

  if [ ${#installed[@]} -gt 0 ]; then
    echo -e "${GREEN}✓ Installed (ui-ux-pro-max):${NC}"
    for t in "${installed[@]}"; do echo "    • $t"; done
  fi

  if [ ${#skipped[@]} -gt 0 ]; then
    echo -e "${GRAY}– Skipped (not detected):${NC}"
    for t in "${skipped[@]}"; do echo "    • $t"; done
  fi

  echo -e "${YELLOW}! Manual steps required (run inside Claude Code):${NC}"
  for m in "${manual[@]}"; do echo "    • $m"; done

  echo "========================================"
}

# --- 主流程 / Main ---
# 取消注释需要安装的工具 / Uncomment tools to install

install_ui_ux_pro_max
