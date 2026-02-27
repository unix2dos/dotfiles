# dotfiles

> macOS 开发环境配置文件集合

## 包含内容

| 配置 | 说明 |
|------|------|
| **zsh** | Zsh shell 配置 (Antidote 插件管理, Starship 提示符) |
| **git** | Git 全局配置 (diff-so-fancy, 别名, LFS) |
| **tmux** | Tmux 配置 (基于 gpakosz/.tmux) |
| **vim** | Vim 编辑器配置 |
| **alacritty** | Alacritty 终端配置 + 主题 |
| **ghostty** | Ghostty 终端配置 |
| **starship** | Starship 提示符主题 |
| **fastfetch** | 系统信息展示配置 |
| **vscode** | VS Code 设置 + 快捷键 |
| **opencode** | Opencode AI 配置 |

## 安装

```bash
git clone https://github.com/unix2dos/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
chmod +x install.sh
./install.sh
```

`install.sh` 会将配置文件**符号链接**到系统对应位置。已有文件会自动备份为 `*.backup.{timestamp}`。

## 依赖工具

以下工具需要提前安装（推荐使用 [Homebrew](https://brew.sh)）：

```bash
brew install eza ripgrep fzf starship fastfetch diff-so-fancy trash bat
brew install --cask alacritty ghostty
```

## 同步（维护者用）

本仓库的配置从私有仓库 `LevonConfig` 同步而来，敏感信息已过滤。

```bash
./sync.sh   # 从 LevonConfig 同步安全配置
git diff     # 检查变更
git add -A && git commit -m "chore: 同步配置"
git push
```

## License

MIT
