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

echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
echo ""
echo "提示: 重启终端或执行 source ~/.zshrc 使配置生效"
