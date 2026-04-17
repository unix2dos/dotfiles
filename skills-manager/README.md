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
| `skills_sources.yaml`   | 下载器配置：从哪 git clone + 怎么 build |
| `skills_consumers.yaml` | 分发器配置：每个 AI 工具装哪些 skill |
| `install.sh`            | 所有逻辑：clean → clone+build → aggregate → distribute |

## Pipeline

```
Step 0  clean             清理 ~/.skills-installed + ~/.skills-community
Step 1  clone + build     拉源仓库、跑 build、抓 extracts
Step 2  aggregate         按优先级聚合到 ~/.skills-installed（symlink 层）
Step 3  distribute        按 consumers 配置创建各 AI 工具的 skill 集
```

## Sources（按优先级 high → low）

| # | Source | Repo | 备注 |
|---|--------|------|------|
| 1 | lw          | unix2dos/skills    | 自有，clone 到 `~/workspace/skills` |
| 2 | superpowers | obra/superpowers   | 工程流程框架 |
| 3 | mini        | slavingia/skills   | 精益创业 |
| 4 | ljg-skills  | lijigang/ljg-skills| npm build |
| 5 | gstack      | garrytan/gstack    | bun build + runtime assets |
| – | extracts    | 多仓库子目录提取    | skill-creator / find-skills / 等 |

同名 skill → 优先级高的胜出。

## Consumer 配置（`skills_consumers.yaml`）

```yaml
core:
  - lw-code-refactor
  - architecture-designer
  # ...

consumers:
  "~/.claude/skills":  { add:  [extra1, extra2] }   # core ∪ {extra1, extra2}
  "~/.codex/skills":   {}                           # 装 core
  "~/.cursor/skills":  { only: [a, b] }             # 只装 a, b（不要 core）
```

**三种写法**：

| 配置 | 实际安装 |
|---|---|
| `{}`              | core |
| `{ add: [a, b] }` | core ∪ {a, b} |
| `{ only: [a, b] }`| {a, b}（不要 core） |

**规则**：
- 出现在 `consumers:` 里 = 被 install.sh 管理；不写 = 完全不碰
- `add` 和 `only` 互斥
- 配置里写了不存在的 skill 名 → `[WARN]` 跳过，不报错

## Source 配置（`skills_sources.yaml`）

```yaml
repos:
  - { repo: owner/name, prefix: xxx }                          # 最简
  - { repo: owner/name, prefix: lw, clone_to: ~/path }         # 本地工作区源
  - { repo: owner/name, name: foo, prefix: "",                 # gstack 风格
      skills_dir: .agents/skills, build: "...",
      runtime_assets: [bin, browse] }

extracts:
  - { repo: owner/name, subdir: path/to/skill, name: my-skill }
```

字段：

| 字段 | 必填 | 说明 |
|---|---|---|
| `repo`           | ✓ | GitHub `owner/name` |
| `prefix`         | 推荐 | skill 名前缀防撞名；`""` 表示不加前缀 |
| `name`           | 可选 | source 标识；不写则用 prefix 或 repo basename |
| `clone_to`       | 可选 | 自定义 clone 路径；默认 `~/.skills-community/{name}` |
| `skills_dir`     | 可选 | skill 根目录，默认 `.` |
| `branch`         | 可选 | 默认 `main` |
| `build`          | 可选 | clone 后执行的命令 |
| `exclude`        | 可选 | 跳过的 skill 名列表 |
| `runtime_assets` | 可选 | symlink 到主 skill 目录的 build 产物 |

## 已知限制

- **不要手动在 consumer 目录放文件**：install.sh 检测到非 symlink 内容会备份到 `{path}.backup.{timestamp}` 后清空
- **core 不支持"减某个"**：要排除某个 skill，用 `only: [...]` 自己列全
- **owned 类源必须显式 `clone_to`**：默认 clone_to 在 `~/.skills-community/`，每次会被 wipe；本地工作区必须指向 `~/.skills-community/` 之外（如 `~/workspace/skills`）

## Project Skills（按需安装，不参与全局）

### [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) — UI/UX 设计智能（67 风格 / 161 配色 / 57 字体）

```bash
npx uipro-cli init --ai claude        # Claude Code
npx uipro-cli init --ai codex         # Codex
npx uipro-cli init --ai antigravity   # Antigravity
npx uipro-cli init --ai all           # 全部平台
```

### [impeccable](https://github.com/pbakaus/impeccable) — 前端 UI/UX 设计智能，20 个斜杠命令

```bash
git clone --depth 1 https://github.com/pbakaus/impeccable.git /tmp/impeccable
cp -r /tmp/impeccable/.claude ./
cp -r /tmp/impeccable/.codex ./
cp -r /tmp/impeccable/.cursor ./
cp -r /tmp/impeccable/.gemini ./
```
