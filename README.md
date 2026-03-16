<p align="center">
  <img src="https://img.shields.io/badge/macOS-000?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/shell-zsh-blue?logo=gnubash&logoColor=white" alt="Zsh">
  <img src="https://img.shields.io/badge/terminal-ghostty-purple" alt="Ghostty">
  <img src="https://img.shields.io/github/last-commit/unix2dos/dotfiles?color=green" alt="Last Commit">
  <img src="https://img.shields.io/github/license/unix2dos/dotfiles" alt="License">
</p>

<h1 align="center">~ dotfiles ~</h1>

<p align="center"><i>macOS 开发环境配置文件集合</i></p>

---

## 📦 主要内容

| 配置 | 说明 |
|:-----|:-----|
| 🐚 [zsh](zsh/) | Zsh shell 配置 (Antidote 插件管理, Starship 提示符) |
| 📝 [git](git/) | Git 全局配置 (diff-so-fancy, 别名, LFS) |
| 🖥️ [tmux](tmux/) | Tmux 配置 (基于 gpakosz/.tmux) |
| ✏️ [vim](vim/) | Vim 编辑器配置 |
| 💻 [alacritty](alacritty/) | Alacritty 终端配置 + 主题 |
| 👻 [ghostty](ghostty/) | Ghostty 终端配置 |
| 🚀 [starship](starship/) | Starship 提示符主题 |
| ⚡ [fastfetch](fastfetch/) | 系统信息展示配置 |
| 🔧 [vscode](vscode/) | VS Code / Cursor / Windsurf / Antigravity / Kiro 设置 + 快捷键 |
| 🤖 [opencode](opencode/) | Opencode AI 配置 |
| 🧠 [claude](claude/) | Claude Code CLI 配置及自定义 Statusline 脚本 |
| 🎯 [skills-manager](skills-manager/) | 全局 AI skills 多来源聚合安装层 |
| 🧰 [ai-kit](ai-kit/) | 项目级 AI 工具安装器 |

## 🚀 安装

```bash
git clone https://github.com/unix2dos/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
chmod +x install.sh && ./install.sh
```

> `install.sh` 会将配置文件**符号链接**到系统对应位置。已有文件会自动备份为 `*.backup.{timestamp}`。

## 🔧 依赖工具

以下工具需要提前安装（推荐使用 [Homebrew](https://brew.sh)）：

```bash
brew install eza ripgrep fzf starship fastfetch diff-so-fancy trash bat
brew install --cask alacritty ghostty
```

## 📖 补充说明

- 全局 skills 管理见 [skills-manager/README.md](skills-manager/README.md)
- 项目级 AI 工具安装见 [ai-kit/README.md](ai-kit/README.md)
- VS Code 相关说明见 [vscode/README.md](vscode/README.md)

## 📄 License

MIT
