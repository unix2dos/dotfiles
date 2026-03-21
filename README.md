<p align="center">
  <img src="https://img.shields.io/badge/macOS-000?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/shell-zsh-blue?logo=gnubash&logoColor=white" alt="Zsh">
  <img src="https://img.shields.io/badge/terminal-ghostty-purple" alt="Ghostty">
  <img src="https://img.shields.io/github/last-commit/unix2dos/dotfiles?color=green" alt="Last Commit">
  <img src="https://img.shields.io/github/license/unix2dos/dotfiles" alt="License">
</p>

<h1 align="center">~ dotfiles ~</h1>

<p align="center"><i>我的开发环境配置文件集合</i></p>

---

## 安装

```bash
# 1. 克隆仓库
git clone https://github.com/unix2dos/dotfiles.git ~/workspace/dotfiles

# 2. 符号链接配置文件（已有文件自动备份为 *.backup.{timestamp}）
cd ~/workspace/dotfiles && ./install.sh

# 3. 安装全局 AI skills（可选，详见 skills-manager/README.md）
bash ~/workspace/dotfiles/skills-manager/install.sh
```

### 依赖

```bash
brew install eza ripgrep fzf starship fastfetch diff-so-fancy trash bat yq
brew install --cask alacritty ghostty
```

---

## 目录结构

### Shell & 终端

| 目录 | 说明 |
|:-----|:-----|
| [zsh](zsh/) | Zsh 配置 (Antidote + Starship) |
| [tmux](tmux/) | Tmux 配置 (基于 gpakosz/.tmux) |
| [alacritty](alacritty/) | Alacritty 终端 + 主题 |
| [ghostty](ghostty/) | Ghostty 终端 |
| [starship](starship/) | Starship 提示符主题 |
| [fastfetch](fastfetch/) | 系统信息展示 |

### 编辑器 & IDE

| 目录 | 说明 |
|:-----|:-----|
| [vim](vim/) | Vim 配置 |
| [git](git/) | Git 全局配置 (diff-so-fancy, 别名, LFS) |
| [vscode](vscode/) | VS Code / Cursor / Windsurf / Antigravity / Kiro 设置 + 快捷键 |

### AI 工具

| 目录 | 说明 |
|:-----|:-----|
| [claude](claude/) | Claude Code CLI 配置 + 自定义 Statusline |
| [opencode](opencode/) | Opencode AI 配置 |
| [amp](amp/) | Amp CLI 配置 |
| [skills-manager](skills-manager/) | 全局 AI skills 聚合层 (owned → superpowers → gstack → community) |

---

## License

MIT
