# VSCode / Cursor / Windsurf / Antigravity / Kiro 配置

> 统一管理所有 VS Code 系编辑器的 `settings.json` 和 `keybindings.json`

## 包含文件

| 文件 | 说明 |
|------|------|
| `settings.json` | 编辑器设置（主题、字体、Go 工具链、Markdown 预览等） |
| `keybindings.json` | 自定义快捷键 |
| `link_all.sh` | 一键创建软链接到所有编辑器 |

## 支持的编辑器

- VS Code (`~/Library/Application Support/Code/User`)
- Cursor (`~/Library/Application Support/Cursor/User`)
- Windsurf (`~/Library/Application Support/Windsurf/User`)
- Antigravity (`~/Library/Application Support/Antigravity/User`)
- Kiro (`~/Library/Application Support/Kiro/User`)

## 使用

```bash
# 一键配置所有编辑器
chmod +x link_all.sh
./link_all.sh
```

脚本会将 `settings.json` 和 `keybindings.json` 软链接到每个已安装的编辑器配置目录。未安装的编辑器会自动跳过。
