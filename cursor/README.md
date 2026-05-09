# Cursor CLI

这个目录存放 Cursor CLI 配置，由根目录的 `install.sh` 管理。

## 文件

| 文件 | 用途 |
|:-----|:-----|
| `statusline.sh` | Cursor status line 调用的命令。 |
| `cli-config.base.json` | 合并到 `~/.cursor/cli-config.json` 的基础 Cursor CLI 配置。 |

## 安装行为

执行根目录安装脚本：

```bash
cd ~/workspace/dotfiles && ./install.sh
```

会执行以下 Cursor 相关操作：

- 将 `cursor/statusline.sh` 软链接到 `~/.cursor/statusline.sh`
- 给 `cursor/statusline.sh` 添加可执行权限
- 如果 `~/.cursor/cli-config.json` 不存在，用 `cursor/cli-config.base.json` 初始化
- 如果 `~/.cursor/cli-config.json` 已存在，把 `cursor/cli-config.base.json` 合并进去

配置合并依赖 `jq`。如果没有安装 `jq`，安装脚本只会跳过 Cursor CLI config
merge，不影响其它配置链接。

## Status Line

`cli-config.base.json` 会让 Cursor 执行：

```json
"statusLine": {
  "type": "command",
  "command": "~/.cursor/statusline.sh",
  "padding": 1,
  "updateIntervalMs": 500,
  "timeoutMs": 1500
}
```

status line 会显示：

- 当前模型名
- 模型参数，以及可用时的 MAX mode 状态
- context 使用量：`total_input_tokens/context_window_size`
- context 使用百分比
- 使用量进度条
- 剩余 context 百分比
- 当前项目目录或 worktree 标签

Cursor 专属的 status line 细节放在这里，不放根目录 README。
