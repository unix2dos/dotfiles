# dotfiles

> macOS 开发环境配置文件集合

## 主要内容

- `zsh`、`git`、`tmux`、`vim`：终端与开发基础配置
- `alacritty`、`ghostty`、`starship`、`fastfetch`：终端外观与系统信息展示
- `vscode`：VS Code / Cursor / Kiro 等编辑器设置
- `claude`、`opencode`：AI 工具配置
- `agents/skills`：统一的 agent skills 运行时安装层

## 安装

```bash
git clone https://github.com/unix2dos/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
chmod +x install.sh
./install.sh
```

`install.sh` 会将配置文件**符号链接**到系统对应位置。已有文件会自动备份为 `*.backup.{timestamp}`。

## 补充说明

- Agent skills 的安装层说明见 [agents/skills/README.md](agents/skills/README.md)
- VS Code 相关说明见 [vscode/README.md](vscode/README.md)

## 依赖工具

以下工具需要提前安装（推荐使用 [Homebrew](https://brew.sh)）：

```bash
brew install eza ripgrep fzf starship fastfetch diff-so-fancy trash bat
brew install --cask alacritty ghostty
```

## License

MIT
