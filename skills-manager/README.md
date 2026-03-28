# Skills Manager

Multi-AI-tool skills aggregation layer.



## Quick Start

```bash
bash ~/workspace/dotfiles/skills-manager/install.sh
bash ~/workspace/dotfiles/skills-manager/install.sh --dry-run  # 仅预览
```



## Files

| File | Purpose |
|---|---|
| `skills_sources.yaml` | 所有配置：来源、优先级、仓库、消费者 |
| `skills_claude.yaml` | Claude Code 白名单（可选，不存在则全量安装） |
| `install.sh` | 所有逻辑：clean → clone → build → aggregate → link → claude |



## Pipeline

```
Step 0  clean     清理旧的 install_dir / community_dir
Step 1  clone     按 sources 克隆或拉取 Git 仓库
Step 2  build     执行 build 命令 + 抓取社区零散 skills
Step 3  link      聚合为 symlink → ~/.skills-installed，分发到各 consumer
Step 4  claude    读取 skills_claude.yaml 白名单，过滤安装到 ~/.claude/skills
```



## Sources (priority high → low)

| # | Name | Repo | Install |
|---|------|------|---------|
| 1 | owned | unix2dos/skills | git clone |
| 2 | superpowers | obra/superpowers | git clone |
| 3 | minimalist-entrepreneur | slavingia/skills | git clone |
| 4 | ljg-skills | lijigang/ljg-skills | git clone + npm build |
| 5 | gstack | garrytan/gstack | git clone + bun build |
| 6 | community | multiple repos | clone + rsync extract |

Same-name skill → higher priority wins.



## Claude Code 白名单 (`skills_claude.yaml`)

Claude Code 的 skill 数量影响 system prompt 长度，因此通过白名单控制安装范围：

- `include_sources` — 按 source 整体纳入
- `include` — 按单个 skill 名称纳入（使用含 prefix 的完整名称）
- 文件不存在时，安装全量 skills



## Project Skills (按需安装)

不参与全局聚合，在项目根目录手动执行。

### [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) — UI/UX 设计智能 (67 风格 / 161 配色 / 57 字体)

```bash
npx uipro-cli init --ai claude        # Claude Code
npx uipro-cli init --ai codex         # Codex
npx uipro-cli init --ai antigravity   # Antigravity
npx uipro-cli init --ai all           # 全部平台
```

### [impeccable](https://github.com/pbakaus/impeccable) — 前端 UI/UX 设计智能，20 个斜杠命令，防 AI 模板感

```bash
git clone --depth 1 https://github.com/pbakaus/impeccable.git /tmp/impeccable
cp -r /tmp/impeccable/.claude ./          # Claude Code
cp -r /tmp/impeccable/.codex ./           # Codex (OpenAI)
cp -r /tmp/impeccable/.cursor ./          # Cursor
cp -r /tmp/impeccable/.gemini ./          # Gemini CLI
```
