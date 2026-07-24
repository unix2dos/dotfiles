# Skills Manager — 安装与配置

Skill 用途说明见 [README.md](./README.md)。

---

## 1. 快速安装

```bash
# 新机器：先 dotfiles，再 skills
cd ~/workspace/dotfiles && ./install.sh
bash ~/workspace/dotfiles/skills-manager/install.sh

# 日常更新
bash ~/workspace/dotfiles/skills-manager/install.sh
bash ~/workspace/dotfiles/skills-manager/install.sh --dry-run   # 仅预览
```

---

## 2. 架构

### 两个仓库

| 仓库 | 路径 | 职责 |
|---|---|---|
| [`unix2dos/skills`](https://github.com/unix2dos/skills) | `~/workspace/skills` | 内容 — 你写的 SKILL.md |
| `dotfiles/skills-manager` | 本目录 | 部署 — 从哪拉、装给谁 |

### Pipeline

```
clean → clone+build → aggregate（~/.skills-installed）→ distribute（~/.claude/skills 等）
```

consumer 目录采用**原地同步**：安装器只替换受管 symlink，按 `preserve` 保留工具自带目录，并把其他真实条目逐个备份。自有 skill 直接链到 `~/workspace/skills`，改 SKILL.md **无需**重跑 install。

### 分发规则

| 规则 | 说明 |
|---|---|
| **core 白名单** | Cursor / Claude 等 `{}` consumer 只装 `skills_consumers.yaml` 的 core |
| **新 skill 进 core** | 在 skills 仓库写完 → 手动加 core 一行 → 跑 install |
| **OpenClaw 例外** | `add: source:skills` 自动装你写的全部 skill |
| **Codex 例外** | `add: source:superpowers` 额外装工程流程 skill |

---

## 3. 日常维护

| 你做了什么 | 重跑 install？ |
|---|---|
| 编辑 `~/workspace/skills/*/SKILL.md` | 否 |
| skills 仓库新建 skill 目录 | 是 |
| 改 `skills_sources.yaml` 或 `skills_consumers.yaml` | 是 |
| 新机器 | 是 |

---

## 4. Sources 一览

按优先级（高 → 低），同名 skill 高优先级胜出。

| Source | Repo | 装到哪 |
|---|---|---|
| skills | `unix2dos/skills` | core 精选 + OpenClaw 全量 |
| superpowers | `obra/superpowers` | 仅 Codex（14 个，带 `superpowers-` 前缀） |
| ljg-skills | `lijigang/ljg-skills` | core 4 个 + 下方非 core |
| mattpocock-engineering | `mattpocock/skills` → `skills/engineering` | core（14 个） |
| mattpocock-productivity | `mattpocock/skills` → `skills/productivity` | core（5 个） |
| mattpocock-in-progress | `mattpocock/skills` → `skills/in-progress` | 可选 source，不进入 core |
| extracts | 多个第三方 repo | 见 `skills_sources.yaml` |

### skills 仓库 · 非 core（OpenClaw 自动，其他需手动加 core）

`book-recommender` · `daily-knowledge` · `daily-tech-digest` · `geo-explorer` · `go-code-review` · `history-autopsy` · `insight-miner` · `news-tracker` · `project-hunter` · `value-judge` · `wisdom-decoder`

### ljg-skills · 非 core

`ljg-book` · `ljg-card` · `ljg-invest` · `ljg-learn` · `ljg-paper` · `ljg-paper-flow` · `ljg-paper-river` · `ljg-present` · `ljg-push` · `ljg-qa` · `ljg-rank` · `ljg-read` · `ljg-relationship` · `ljg-skill-map` · `ljg-word-flow`

（已 exclude：`ljg-word`、`ljg-travel`）

### superpowers · Codex 专用

brainstorming · writing-plans · executing-plans · test-driven-development · systematic-debugging · verification-before-completion · requesting-code-review · using-git-worktrees · subagent-driven-development · dispatching-parallel-agents · finishing-a-development-branch · receiving-code-review · using-superpowers · writing-skills

---

## 5. 配置参考

### 文件

| 文件 | 用途 |
|---|---|
| `skills_sources.yaml` | 从哪 clone、怎么 build |
| `skills_consumers.yaml` | 每个 AI 工具装哪些 skill |
| `install.sh` | 全部逻辑 |

### Consumer 写法

```yaml
"~/.cursor/skills": {}                              # 装 core
"~/.codex/skills":  { preserve: [.system] }         # core + 保留 Codex 系统 skill
"~/.some/tool":     { only: [a, b] }                # 完全自定义
```

| 配置 | 效果 |
|---|---|
| `{}` | core |
| `{ add: [...] }` | core ∪ 额外 |
| `{ only: [...] }` | 仅 listed，不要 core |
| `{ preserve: [...] }` | 原地保留指定顶层条目；可与 `add` / `only` 共用 |

引用：`code-refactor`（单个）· `source:superpowers`（整源）· `source:skills` · `source:extract`

### Source 字段

| 字段 | 说明 |
|---|---|
| `repo` | GitHub `owner/name` |
| `prefix` | 前缀；`""` = 不加 |
| `clone_to` | 克隆路径；自有源必须指向 `~/.skills-community/` 外 |
| `skills_dir` | skill 根目录 |
| `build` | clone 后执行的命令 |
| `exclude` | 跳过的 skill |

---

## 6. 已知限制

- consumer 目录里的未声明真实条目会被逐个备份；工具自带目录应加入 `preserve`
- core 不支持「减某个」— 用 `only: [...]` 自己列全
- owned 源必须显式 `clone_to` — 默认路径每次 install 会被 wipe

### 按需安装（不经 skills-manager）

**[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** — `npx uipro-cli init --ai all`

**[impeccable](https://github.com/pbakaus/impeccable)** — clone 后复制 `.cursor` / `.codex` 等到项目目录
