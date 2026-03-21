# Skills Manager

Multi-AI-tool skills aggregation layer.

## Quick Start

```bash
bash ~/workspace/dotfiles/skills-manager/install.sh
```

## Files

| File | Purpose |
|---|---|
| `sources.yaml` | All config: sources, priorities, repos, consumers |
| `install.sh` | All logic: clone → build → aggregate → link |

Edit `sources.yaml`, run `install.sh`.

## Sources (priority high → low)

| # | Name | Repo | Install |
|---|------|------|---------|
| 1 | owned | unix2dos/skills | git clone |
| 2 | superpowers | obra/superpowers | git clone |
| 3 | gstack | garrytan/gstack | git clone + bun build |
| 4 | community | multiple repos | clone + rsync extract |

Same-name skill → higher priority wins.

## Project Skills (按需安装)

不参与全局聚合，在项目根目录手动执行：

```bash
npx uipro-cli init --ai claude        # Claude Code
npx uipro-cli init --ai codex         # Codex
npx uipro-cli init --ai antigravity   # Antigravity
npx uipro-cli init --ai all           # 全部平台
```

> [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) — UI/UX 设计智能 (67 风格 / 161 配色 / 57 字体)

详见 `sources.yaml` 中的 `project_skills` 声明。