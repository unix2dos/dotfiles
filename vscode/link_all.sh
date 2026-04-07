#!/bin/bash

# =================配置区域=================
# 源文件所在目录
SOURCE_DIR="$HOME/workspace/dotfiles/vscode"
SOURCE_SETTINGS="$SOURCE_DIR/settings.json"
SOURCE_KEYBINDINGS="$SOURCE_DIR/keybindings.json"

# 需要同步的目标目录列表
# 注意：路径中的空格不需要转义，引号已经处理了
TARGET_APPS_DIRS=(
    #"$HOME/Library/Application Support/Code/User"
    "$HOME/Library/Application Support/Cursor/User"
    "$HOME/Library/Application Support/Antigravity/User"
    #"$HOME/Library/Application Support/Kiro/User"
    #"$HOME/Library/Application Support/Windsurf/User"
)
# =========================================

# 1. 检查源文件是否存在
if [ ! -f "$SOURCE_SETTINGS" ] || [ ! -f "$SOURCE_KEYBINDINGS" ]; then
    echo "❌ 错误：源文件未找到！请检查以下路径是否存在："
    echo "   $SOURCE_SETTINGS"
    echo "   $SOURCE_KEYBINDINGS"
    exit 1
fi

echo "🚀 开始同步配置文件..."

# 2. 循环处理每个 App
for TARGET_DIR in "${TARGET_APPS_DIRS[@]}"; do
    # 检查 App 的配置目录是否存在
    if [ -d "$TARGET_DIR" ]; then
        echo "------------------------------------------------"
        echo "📂正在处理: $TARGET_DIR"

        # --- 处理 settings.json ---
        # 删除旧文件或旧链接
        rm -rf "$TARGET_DIR/settings.json"
        # 创建软链接 (-s:软链接, -f:强制)
        ln -sf "$SOURCE_SETTINGS" "$TARGET_DIR/settings.json"
        echo "  ✅ settings.json 软链成功"

        # --- 处理 keybindings.json ---
        # 删除旧文件或旧链接
        rm -rf "$TARGET_DIR/keybindings.json"
        # 创建软链接
        ln -sf "$SOURCE_KEYBINDINGS" "$TARGET_DIR/keybindings.json"
        echo "  ✅ keybindings.json 软链成功"

    else
        echo "------------------------------------------------"
        echo "⚠️ 跳过: $TARGET_DIR (目录不存在，可能未安装此软件)"
    fi
done

echo "------------------------------------------------"
echo "🎉 所有操作完成！"

