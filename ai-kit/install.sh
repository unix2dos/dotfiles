#!/bin/bash
# ============================================
# AI Kit — 项目级 AI 工具安装脚本
# Project-level AI tools installer
# ============================================
# 在项目目录下执行此脚本，按需安装所需的 AI 工具。
# Run this script in your project directory to install AI tools.
# ============================================

set -euo pipefail

# --- ui-ux-pro-max-skill ---
# 专业 UI/UX 设计智能工具，安装后 Claude 可访问 67 种 UI 风格、
# 161 个配色方案、57 种字体配对的设计知识库。
# Professional UI/UX design intelligence for Claude.
install_ui_ux_pro_max() {
  if ! command -v uipro &>/dev/null; then
    echo "[ai-kit] Installing uipro-cli..."
    npm install -g uipro-cli
  fi
  echo "[ai-kit] Initializing ui-ux-pro-max for Claude Code..."
  uipro init --ai claude
}

# --- 主流程 / Main ---
# 取消注释需要安装的工具 / Uncomment tools you want to install

# install_ui_ux_pro_max

echo "[ai-kit] Done. Uncomment tools in install.sh to enable them."
