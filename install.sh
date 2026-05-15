#!/bin/bash
# ============================================
# dotfiles 安装脚本
# ============================================
# 将 dotfiles 仓库中的配置文件链接到系统对应位置
# 用法: ./install.sh
# ============================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 安全链接函数 ---
link_file() {
    local src="$1"
    local dst="$2"

    if [ ! -e "$src" ]; then
        echo -e "${YELLOW}  ⚠ 跳过（源文件不存在）: $src${NC}"
        return
    fi

    mkdir -p "$(dirname "$dst")"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            echo -e "${GREEN}  ✓${NC} 已链接: $(basename "$dst")"
            return
        fi
        # 备份已有文件
        local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$backup"
        echo -e "${YELLOW}  ⚠ 已备份: $(basename "$dst") → $(basename "$backup")${NC}"
    fi

    ln -s "$src" "$dst"
    echo -e "${GREEN}  ✓${NC} 链接: $(basename "$dst")"
}

# Merge ~/.cursor/mcp.json from repo cursor/mcp.json + optional ~/.cursor/mcp.local.json
# (local wins on duplicate server names). If mcp.local.json is absent, symlink repo file.
install_cursor_mcp() {
    local base="$DOTFILES/cursor/mcp.json"
    local local_mcp="$HOME/.cursor/mcp.local.json"
    local dst="$HOME/.cursor/mcp.json"

    if [ ! -f "$base" ]; then
        echo -e "${YELLOW}  ⚠ 跳过 Cursor mcp（源文件不存在）: $base${NC}"
        return
    fi

    mkdir -p "$HOME/.cursor"

    if [ -f "$local_mcp" ]; then
        if ! command -v jq >/dev/null 2>&1; then
            echo -e "${YELLOW}  ⚠ 发现 mcp.local.json 但 jq 未安装：无法合并，改用仓库目录的软链接${NC}"
            link_file "$base" "$dst"
            return
        fi
        local tmp
        tmp="$(mktemp)"
        jq -s '.[0] as $a | .[1] as $b | { mcpServers: (($a.mcpServers // {}) * ($b.mcpServers // {})) }' \
            "$base" "$local_mcp" > "$tmp"
        if { [ -f "$dst" ] || [ -L "$dst" ]; } && cmp -s "$tmp" "$dst"; then
            rm -f "$tmp"
            echo -e "${GREEN}  ✓${NC} Cursor mcp.json（合并）无变化"
            return
        fi
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
            mv "$dst" "$backup"
            echo -e "${YELLOW}  ⚠ 已备份: $(basename "$dst") → $(basename "$backup")${NC}"
        fi
        mv "$tmp" "$dst"
        echo -e "${GREEN}  ✓${NC} Cursor mcp.json 已合并（仓库 + ~/.cursor/mcp.local.json）"
    else
        link_file "$base" "$dst"
    fi
}

echo "🔗 安装 dotfiles..."
echo "   源: $DOTFILES"
echo ""

# --- Shell ---
echo "🐚 Shell"
link_file "$DOTFILES/zsh/.zshrc"                "$HOME/.zshrc"

# --- Git ---
echo "📝 Git"
link_file "$DOTFILES/git/.gitconfig"            "$HOME/.gitconfig"
link_file "$DOTFILES/git/ignore"                "$HOME/.config/git/ignore"

# --- 终端 ---
echo "💻 终端"
link_file "$DOTFILES/tmux/.tmux.conf.local"     "$HOME/.tmux.conf.local"
link_file "$DOTFILES/alacritty/alacritty.toml"  "$HOME/.config/alacritty/alacritty.toml"
link_file "$DOTFILES/ghostty/config"            "$HOME/.config/ghostty/config"

# --- 编辑器 ---
echo "✏️  编辑器"
link_file "$DOTFILES/vim/.vimrc"                "$HOME/.vimrc"
bash "$DOTFILES/vscode/link_all.sh"

# --- 提示符 & 系统信息 ---
echo "🎨 提示符 & 系统信息"
link_file "$DOTFILES/starship/starship.toml"    "$HOME/.config/starship.toml"
link_file "$DOTFILES/fastfetch/config.jsonc"    "$HOME/.config/fastfetch/config.jsonc"

# --- AI 工具 ---
echo "🤖 AI 工具"
link_file "$DOTFILES/opencode/opencode.json"        "$HOME/.config/opencode/opencode.json"
link_file "$DOTFILES/opencode/oh-my-opencode.json"  "$HOME/.config/opencode/oh-my-opencode.json"
link_file "$DOTFILES/claude/settings.json"          "$HOME/.claude/settings.json"
link_file "$DOTFILES/claude/CLAUDE.md"              "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES/claude/statusline-hud-wrapper.sh"  "$HOME/.claude/statusline-hud-wrapper.sh"
link_file "$DOTFILES/claude/plugins/claude-hud/config.json" "$HOME/.claude/plugins/claude-hud/config.json"
link_file "$DOTFILES/amp/settings.json"             "$HOME/.config/amp/settings.json"
link_file "$DOTFILES/codex/config.toml"             "$HOME/.codex/config.toml"
if [ -f "$DOTFILES/cursor/statusline.sh" ]; then
  link_file "$DOTFILES/cursor/statusline.sh" "$HOME/.cursor/statusline.sh"
  chmod +x "$DOTFILES/cursor/statusline.sh"
fi
install_cursor_mcp
if [ -f "$DOTFILES/cursor/cli-config.base.json" ]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}  ⚠ 跳过 Cursor cli-config merge（jq 未安装）${NC}"
  else
    mkdir -p "$HOME/.cursor"
    if [ ! -f "$HOME/.cursor/cli-config.json" ]; then
      cp "$DOTFILES/cursor/cli-config.base.json" "$HOME/.cursor/cli-config.json"
      echo -e "${GREEN}  ✓${NC} Cursor cli-config 已初始化"
    fi
    tmp_config="$(mktemp)"
    if [ -f "$HOME/.cursor/cli-config.local.json" ]; then
      jq -s '.[0] * .[1] * .[2]' \
        "$HOME/.cursor/cli-config.json" \
        "$DOTFILES/cursor/cli-config.base.json" \
        "$HOME/.cursor/cli-config.local.json" > "$tmp_config"
    else
      jq -s '.[0] * .[1]' \
        "$HOME/.cursor/cli-config.json" \
        "$DOTFILES/cursor/cli-config.base.json" > "$tmp_config"
    fi
    mv "$tmp_config" "$HOME/.cursor/cli-config.json"
    echo -e "${GREEN}  ✓${NC} Cursor cli-config 已合并"
  fi
fi

echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
echo ""
echo "提示: 重启终端或执行 source ~/.zshrc 使配置生效"
