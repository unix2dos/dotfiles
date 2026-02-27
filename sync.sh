#!/bin/bash
# ============================================
# dotfiles 同步脚本
# ============================================
# 从 LevonConfig (private) 同步安全配置到 dotfiles (public)
# 用法: ./sync.sh
# ============================================

set -euo pipefail

# --- 配置 ---
LEVON="${HOME}/workspace/LevonConfig"
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 检查源目录 ---
if [ ! -d "$LEVON" ]; then
    echo -e "${RED}✗ LevonConfig 目录不存在: $LEVON${NC}"
    exit 1
fi

echo "📦 从 LevonConfig 同步配置到 dotfiles..."
echo "   源: $LEVON"
echo "   目标: $DOTFILES"
echo ""

# --- 同步函数 ---
sync_file() {
    local src="$1"
    local dst="$2"

    if [ ! -e "$src" ]; then
        echo -e "${YELLOW}  ⚠ 跳过（源文件不存在）: $src${NC}"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo -e "${GREEN}  ✓${NC} $(basename "$dst")"
}

sync_dir() {
    local src="$1"
    local dst="$2"

    if [ ! -d "$src" ]; then
        echo -e "${YELLOW}  ⚠ 跳过（源目录不存在）: $src${NC}"
        return
    fi

    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/ 2>/dev/null || true
    echo -e "${GREEN}  ✓${NC} $(basename "$dst")/"
}

# --- Shell ---
echo "🐚 Shell"
sync_file "$LEVON/Config/zsh/.zshrc"               "$DOTFILES/zsh/.zshrc"

# --- Git ---
echo "📝 Git"
sync_file "$LEVON/Config/git/.gitconfig"            "$DOTFILES/git/.gitconfig"
sync_file "$LEVON/Config/git/ignore"                "$DOTFILES/git/ignore"
# ⚠️ 注意: czrc 包含 API Key，不同步
# ⚠️ 注意: .gitconfig-work 包含工作邮箱和内部地址，不同步

# --- 终端 ---
echo "💻 终端"
sync_file "$LEVON/Config/tmux/.tmux.conf.local"     "$DOTFILES/tmux/.tmux.conf.local"
sync_file "$LEVON/Config/alacritty/alacritty.toml"  "$DOTFILES/alacritty/alacritty.toml"
sync_dir  "$LEVON/Config/alacritty/themes"           "$DOTFILES/alacritty/themes"
sync_file "$LEVON/Config/ghostty/config"             "$DOTFILES/ghostty/config"

# --- 编辑器 ---
echo "✏️  编辑器"
sync_file "$LEVON/Config/vim/.vimrc"                 "$DOTFILES/vim/.vimrc"
sync_file "$LEVON/Config/vscode/settings.json"       "$DOTFILES/vscode/settings.json"
sync_file "$LEVON/Config/vscode/keybindings.json"    "$DOTFILES/vscode/keybindings.json"

# --- 提示符 & 系统信息 ---
echo "🎨 提示符 & 系统信息"
sync_file "$LEVON/Config/starship/starship.toml"     "$DOTFILES/starship/starship.toml"
sync_file "$LEVON/Config/fastfetch/config.jsonc"     "$DOTFILES/fastfetch/config.jsonc"

# --- AI 工具 ---
echo "🤖 AI 工具"
sync_file "$LEVON/Config/opencode/opencode.json"         "$DOTFILES/opencode/opencode.json"
sync_file "$LEVON/Config/opencode/oh-my-opencode.json"   "$DOTFILES/opencode/oh-my-opencode.json"

echo ""
echo -e "${GREEN}✅ 同步完成！请检查变更后 git commit${NC}"
echo ""
echo "提示: cd $DOTFILES && git diff"
