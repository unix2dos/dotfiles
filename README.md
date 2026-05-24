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

# 3. 安装全局 AI skills（可选，详见 skills-manager/INSTALL.md）
bash ~/workspace/dotfiles/skills-manager/install.sh
```

### 依赖

```bash
brew install eza ripgrep fzf starship fastfetch diff-so-fancy trash bat yq
brew install --cask alacritty ghostty
```

---

## 目录结构

### AI 工具

| 目录 | 说明 |
|:-----|:-----|
| [claude](claude/) | Claude Code CLI 配置 |
| [amp](amp/) | Amp CLI 配置 |
| [codex](codex/) | Codex CLI 配置 |
| [cursor](cursor/) | Cursor CLI 配置和 status line |
| [opencode](opencode/) | Opencode AI 配置 |
| [skills-manager](skills-manager/) | 全局 AI skills 聚合层 |

### Shell & 终端

| 目录 | 说明 |
|:-----|:-----|
| [zsh](zsh/) | Zsh 配置 (Antidote + Starship) |
| [tmux](tmux/) | Tmux 配置 (基于 gpakosz/.tmux，含 popup / pane switcher / 状态栏脚本) |
| [alacritty](alacritty/) | Alacritty 终端 + 主题 |
| [ghostty](ghostty/) | Ghostty 终端 |
| [starship](starship/) | Starship 提示符主题 |
| [fastfetch](fastfetch/) | 系统信息展示 |
| [git](git/) | Git 全局配置 (diff-so-fancy, 别名, LFS) |

#### Tmux 快捷入口

详见 [tmux/README.md](tmux/README.md) 和 [tmux/cheatsheet.txt](tmux/cheatsheet.txt)。

| 快捷键 | 功能 |
|:-------|:-----|
| `Cmd+p` / `M-p` | 项目浮动终端：按当前 pane 目录复用 `_popup` window，并自动 `git status` |
| `M-q` | AI pane 切换：查找 `claude` / `codex` / `gemini` / `amp` 等运行中的 pane |
| `M-w` | 全局 pane 切换：fzf 预览并跳转所有 tmux pane |
| `Cmd+o` | 智能打开：优先打开剪贴板路径，否则打开当前 pane 目录 |

### 编辑器

| 目录 | 说明 |
|:-----|:-----|
| [vim](vim/) | Vim 配置 |
| [vscode](vscode/) | VS Code / Cursor / Windsurf / Antigravity / Kiro 设置 + 快捷键 |

---

## License

MIT
