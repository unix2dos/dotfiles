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

consumer 目录采用**原地同步**：安装器只替换 symlink，所有真实目录都视为外部工具管理并原地保留。自有 skill 直接链到 `~/workspace/skills`，改 SKILL.md **无需**重跑 install。

### 分发规则

| 规则 | 说明 |
|---|---|
| **core 白名单** | Cursor / Claude 等 `{}` consumer 只装 `skills_consumers.yaml` 的 core |
| **新 skill 进 core** | 在 skills 仓库写完 → 手动加 core 一行 → 跑 install |

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
| unix2dos | `unix2dos/skills` | 整源进入 core（受 `exclude` 限制） |
| ljg-skills | `lijigang/ljg-skills` | 稀疏检出并聚合 core 4 个 |
| mattpocock-engineering | `mattpocock/skills` → `skills/engineering` | core（14 个） |
| mattpocock-productivity | `mattpocock/skills` → `skills/productivity` | core（5 个） |
| mattpocock-in-progress | `mattpocock/skills` → `skills/in-progress` | 可选 source，不进入 core |
| extracts | 多个第三方 repo | 见 `skills_sources.yaml` |

### ljg-skills · 精选

仅保留 `ljg-plain` · `ljg-think` · `ljg-writes` · `ljg-roundtable`。`include` 会同时限制 Git sparse checkout 和聚合；不再执行 `ljg-card` 的 npm / Playwright build。

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
"~/.codex/skills":  {}                              # 装 core；真实目录自动保留
"~/.some/tool":     { only: [a, b] }                # 完全自定义
```

| 配置 | 效果 |
|---|---|
| `{}` | core |
| `{ add: [...] }` | core ∪ 额外 |
| `{ only: [...] }` | 仅 listed，不要 core |

引用：`code-refactor`（单个）· `source:unix2dos`（整源）· `source:extract`

### Source 字段

| 字段 | 说明 |
|---|---|
| `repo` | GitHub `owner/name` |
| `prefix` | 前缀；`""` = 不加 |
| `clone_to` | 克隆路径；自有源必须指向 `~/.skills-community/` 外 |
| `skills_dir` | skill 根目录 |
| `build` | clone 后执行的命令 |
| `include` | 只稀疏检出并聚合列出的 skill |
| `exclude` | 跳过的 skill |

---

## 6. 已知限制

- consumer 目录里的真实条目不会被同步或删除；同名真实条目优先于受管 skill
- core 不支持「减某个」— 用 `only: [...]` 自己列全
- owned 源必须显式 `clone_to` — 默认路径每次 install 会被 wipe

### 按需安装（不经 skills-manager）

**[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** — `npx uipro-cli init --ai all`

**[impeccable](https://github.com/pbakaus/impeccable)** — clone 后复制 `.cursor` / `.codex` 等到项目目录
