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
#    注意: 此步骤会自动写入 2 条 crontab 任务（见下方"定时任务"章节）
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

### AI 工具

| 目录 | 说明 |
|:-----|:-----|
| [claude](claude/) | Claude Code CLI 配置 (settings + CLAUDE.md + claude-hud 插件 + daily-hello 定时任务) |
| [amp](amp/) | Amp CLI 配置 + daily-hello 定时任务 |
| [codex](codex/) | Codex CLI 配置 (config.toml + AGENTS.md) |
| [opencode](opencode/) | Opencode AI 配置 |
| [skills-manager](skills-manager/) | 全局 AI skills 聚合层 (owned → superpowers → gstack → community) |

### Shell & 终端

| 目录 | 说明 |
|:-----|:-----|
| [zsh](zsh/) | Zsh 配置 (Antidote + Starship) |
| [tmux](tmux/) | Tmux 配置 (基于 gpakosz/.tmux) |
| [alacritty](alacritty/) | Alacritty 终端 + 主题 |
| [ghostty](ghostty/) | Ghostty 终端 |
| [starship](starship/) | Starship 提示符主题 |
| [fastfetch](fastfetch/) | 系统信息展示 |
| [git](git/) | Git 全局配置 (diff-so-fancy, 别名, LFS) |

### 编辑器

| 目录 | 说明 |
|:-----|:-----|
| [vim](vim/) | Vim 配置 |
| [vscode](vscode/) | VS Code / Cursor / Windsurf / Antigravity / Kiro 设置 + 快捷键 |

---

## 定时任务

`install.sh` 末尾会自动写入 2 条 crontab（已存在则跳过）：

| 计划 | 任务 |
|:-----|:-----|
| `0 16 * * *` | [amp/amp-daily-hello.sh](amp/amp-daily-hello.sh) |
| `0 9,14,19 * * *` | [claude/claude-daily-hello.sh](claude/claude-daily-hello.sh) |

每条任务执行后都会调用 [schedule-next-wake.sh](schedule-next-wake.sh)，通过 `sudo pmset schedule wake` 预约下一个整点（08:59 / 13:59 / 15:59 / 18:59）唤醒，确保 Mac 在睡眠时也能按时触发。

> ⚠️ `pmset` 需要 sudo 权限，建议在 `/etc/sudoers.d/` 配置 `pmset` 免密，否则任务无法静默执行。
> 日志输出到 `~/.local/log/wake-schedule.log`。

如不需要这些定时任务，安装后执行 `crontab -e` 删除对应行即可。

---

## License

MIT
