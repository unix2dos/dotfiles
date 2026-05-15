# tmux

这个目录存放本机 tmux 配置覆盖层和配套脚本。

整体配置基于 [gpakosz/.tmux](https://github.com/gpakosz/.tmux)，也就是
Oh My Tmux。上游模板负责大部分默认行为、主题变量、插件启动和基础按键。
本仓库把个人覆盖配置放在 `tmux/.tmux.conf.local`。

## 配置模型

### 上游层：Oh My Tmux

Oh My Tmux 负责通用 tmux 框架：

- `tmux_conf_*` 变量：主题、状态栏、剪贴板、插件生命周期、session/window/pane 行为。
- 默认快捷键约定。
- 通过 `set -g @plugin ...` 声明 TPM 风格插件。
- 状态栏主题使用的扩展变量和 helper。

修改大范围 tmux 行为时，优先调整已有的 `tmux_conf_*` 变量；这是 Oh My
Tmux 预留的定制入口。只有变量无法表达时，再加原生 tmux 命令。

### 本地层：`.tmux.conf.local`

本地覆盖层定义这台机器的使用习惯：

- Prefix 是 `Ctrl+a`。
- 状态栏显示在顶部。
- 开启鼠标支持。
- 状态栏和 copy-mode 使用 vi 键位。
- copy-mode 中禁用 `t/T` jump prompt，避免误触黄色 `(jump to forward)` 输入栏。
- `Cmd+o` 通过 tmux `user-keys` 捕获，并转发给 `smart-open.sh`。
- `M-p`、`M-q`、`M-w` 是无需 prefix 的自定义 popup 工作流。
- 开启 `extended-keys` + `csi-u`，让 pi 等 TUI 在 tmux 内正确识别 Shift/Ctrl/Alt 组合键。
- 状态栏显示网速、tmux mode indicator 和 session 状态。

维护时尽量把自定义行为放在 `.tmux.conf.local` 现有编号区块附近。如果某个
binding 超过几行，把逻辑移到本目录脚本里，tmux 配置只保留薄入口。

## 插件

当前启用的插件：

| 插件 | 用途 |
|:-----|:-----|
| `tmux-plugins/tmux-copycat` | 搜索/复制增强，包括 `Prefix+/`。 |
| `tmux-plugins/tmux-cpu` | CPU 和内存状态栏 helper。 |
| `MunifTanjim/tmux-mode-indicator` | 状态栏模式指示器。 |
| `tmux-plugins/tmux-resurrect` | 手动保存/恢复 tmux 会话。 |
| `tmux-plugins/tmux-continuum` | 自动保存/恢复 tmux 会话。 |
| `laktak/extrakto` | 基于 fzf 的提取/复制工作流，入口是 `Prefix+f`。 |

本地配置关闭了插件自动更新和自动卸载，避免 reload 时因为网络或插件源问题改变
已安装插件集合。需要维护插件时，手动使用 TPM 的正常命令。

## 快捷键

| 快捷键 | 脚本 | 用途 |
|:-------|:-----|:-----|
| `Cmd+p` / `M-p` | `popup_terminal.sh` | 打开/收起持久项目浮动终端。 |
| `M-q` | `ai_pane_switch_popup.sh` | 查找并跳转到运行中的 AI CLI pane，包括 pi。 |
| `M-w` | `pane_switch_popup.sh` | 查找并跳转到任意 tmux pane。 |
| `Cmd+o` | `smart-open.sh` | 打开剪贴板路径；没有合法路径时打开当前 pane 目录。 |
| 状态栏 | `net_speed.sh` | 渲染紧凑的网络上下行速度。 |

`Cmd+p` 由 Ghostty 映射成和 `M-p` 相同的转义序列。

## 维护规则

- 快捷键速查写在 `cheatsheet.txt`。
- 工作流和脚本行为说明写在本文档。
- 脚本头部只写短说明：触发入口、行为、安全注意点。
- 优先使用脚本，避免在 `.tmux.conf.local` 里写很长的转义 `run-shell`。
- 避免隐藏的 `send-keys` 流程；确实需要时，先检查目标 pane/window 状态。

## 脚本

### `popup_terminal.sh`

用于快速进入项目目录的持久浮动终端。

- 由 `Cmd+p` / `M-p` 调用。
- 使用单个 `_popup` tmux session。
- 每个来源 pane 目录创建或复用一个 `_popup` window。
- 通过目录 window 复用实现快速切换，不再盲打 `cd`。
- 默认 `TMUX_POPUP_MAX_WINDOWS=5`。
- 达到软上限时，只关闭非活跃的 shell window。
- 如果现有 window 都在运行非 shell 命令，允许临时超过上限，不强杀工作状态。
- 路由到 shell window 后，会发送 `Ctrl+L` 并执行 `git status`。
- 不会向 `nvim`、`claude`、`codex`、`top`、`ssh` 等非 shell window 发送按键。

### `ai_pane_switch_popup.sh`

AI pane 切换器。

- 由 `M-q` 调用。
- 查找进程树里包含 `claude`、`codex`、`gemini`、`amp`、`pi`、`agent`、`droid` 等 AI CLI 的 pane。
- 用 tmux popup + fzf 展示结果。
- 预览内容由 `ai_pane_summary.sh` 提供。
- popup 内 `M-r` 刷新摘要。
- popup 内 `M-t` 显示/隐藏预览区域。

### `ai_pane_summary.sh`

AI pane 预览 helper。

- 捕获目标 pane 内容。
- 为 `ai_pane_switch_popup.sh` 生成带缓存的摘要。
- 打开 AI pane 列表时懒刷新过期或内容变化的缓存；不做常驻后台轮询。
- 打开 AI pane 列表时只懒刷新缺失或超过 TTL 的缓存；不因内容变化立即刷新。
- 支持 raw preview，不需要模型摘要时直接显示原始内容。
- 缓存目录是 `${TMPDIR:-/tmp}/ai_pane_summary_cache`。
- 摘要 TTL 默认 300 秒，可用 `AI_PANE_SUMMARY_TTL` 调整。

### `pane_switch_popup.sh`

全局 pane 切换器。

- 由 `M-w` 调用。
- 用 fzf 列出所有 tmux pane。
- 为选中的 pane 显示实时 capture preview。
- 跳转到选中的 pane；如果当前在 `_popup` session 里，会先 detach，让目标 pane 可见。

### `smart-open.sh`

tmux 里的 macOS 智能打开器。

- 由 `Cmd+o` 触发，底层通过 tmux `user-keys[0]` 捕获。
- 如果剪贴板里是存在的路径，则打开该路径。
- 否则打开当前 pane 目录。
- 支持 `file://` 前缀和 `~` 展开。

### `net_speed.sh`

状态栏网络速度渲染器。

- 读取 macOS 网络计数器。
- 把上一次采样存到 `/tmp/.tmux_net_speed_<iface>`。
- 输出固定宽度状态片段，避免状态栏抖动。

## 配置文件

主配置：

- `tmux/.tmux.conf.local`

快捷键速查：

- `tmux/cheatsheet.txt`
