# Cursor CLI

这个目录存放 Cursor CLI 配置，由根目录的 `install.sh` 管理。

## 文件

| 文件 | 用途 |
|:-----|:-----|
| `statusline.sh` | Cursor status line 调用的命令。 |
| `cli-config.base.json` | 合并到 `~/.cursor/cli-config.json` 的基础 Cursor CLI 配置。 |
| `mcp.json` | 默认软链接到 `~/.cursor/mcp.json`；若存在 `~/.cursor/mcp.local.json` 则改为“仓库 + 本地”合并生成。 |
| `mcp.local.json.example` | 复制为 `~/.cursor/mcp.local.json` 的模板（仅存本机，不进 git）。 |
| `cli-config.local.json.example` | 复制为 `~/.cursor/cli-config.local.json` 的模板（仅存本机，不进 git）。 |

## 安装行为

执行根目录安装脚本：

```bash
cd ~/workspace/dotfiles && ./install.sh
```

会执行以下 Cursor 相关操作：

- 将 `cursor/statusline.sh` 软链接到 `~/.cursor/statusline.sh`
- 给 `cursor/statusline.sh` 添加可执行权限
- **MCP**：若 **没有** `~/.cursor/mcp.local.json`，将 `cursor/mcp.json` **软链接**到 `~/.cursor/mcp.json`。若 **有** `mcp.local.json` 且已安装 `jq`，则把仓库的 `mcp.json` 与 `~/.cursor/mcp.local.json` 合并写入 `~/.cursor/mcp.json`（同名 `mcpServers` 以本地为准）。
- **CLI 配置**：如果 `~/.cursor/cli-config.json` 不存在，用 `cursor/cli-config.base.json` 初始化；然后始终做合并：当前 `cli-config.json` × 仓库 `cli-config.base.json` ×（可选）`~/.cursor/cli-config.local.json`，后者覆盖前者同名字段。
- 合并依赖 `jq`。若未安装 `jq`：跳过 CLI 合并；MCP 在有 `mcp.local.json` 时会回退为仅软链接仓库（并提示无法合并），其它配置链接不受影响。

## 本机覆盖文件（勿提交密钥）

将示例复制到 `$HOME/.cursor/`（不要放进仓库目录 `cursor/` 下的同名文件，以免误操作）：

```bash
cp cursor/mcp.local.json.example ~/.cursor/mcp.local.json
# optional:
# cp cursor/cli-config.local.json.example ~/.cursor/cli-config.local.json
```

编辑后重新执行 `./install.sh`。不要把 token 明文写进 git 里的 `mcp.json`；用环境变量或只写在 `~/.cursor/mcp.local.json`。

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

## MCP

无 `~/.cursor/mcp.local.json` 时：`mcp.json` 直接软链接到 `~/.cursor/mcp.json`，Cursor IDE 和 Cursor CLI (`cursor-agent`) 共享同一份配置。

启用 `mcp.local.json` 后：合并结果写在真实的 `~/.cursor/mcp.json`，**下一次运行 `install.sh` 会按「仓库 + local」重新生成该文件**；在 Cursor GUI 里临时添加的 MCP 若未同步进仓库或 `mcp.local.json`，可能在下次安装时被覆盖。改完 `cursor/mcp.json` 或 `~/.cursor/mcp.local.json` 后执行 `./install.sh`，改 GUI 后记得 `git diff`（仅在使用软链接模式且写回仓库时）。

注意事项：

- 在 Cursor GUI 里点 "Add MCP" 会直接写 `~/.cursor/mcp.json`；在 **软链接模式** 下即写到 dotfiles 仓库里的 `cursor/mcp.json`，改完记得 `git status`。
- 需要 token 的 server 请用 `${ENV_VAR}` 引用环境变量，或只写在 `~/.cursor/mcp.local.json`。
