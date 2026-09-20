# Skills Manager

用一份配置把 Agent Skills 分发到多个 AI 工具，并安装 Ponytail 这类宿主原生扩展。

## 文件

```text
skills-manager/
├── README.md
├── config.yaml
├── install.sh
├── installers/
│   └── ponytail.sh
└── bundle/           # install.sh 生成，提交进 git 供云 Agent 安装
```

## 使用

依赖：`bash`、`git`、`rsync`、[yq](https://github.com/mikefarah/yq)。Codex、Cursor 等宿主未安装时，对应 Extension 会跳过。

```bash
# 查看最终每个目录有什么，不联网、不修改文件
bash install.sh --preview

# 展开完整 Skill 名称
bash install.sh --preview --full

# 查看将执行的 clone、链接和 Extension 命令
bash install.sh --dry-run

# 安装或更新
bash install.sh
```

## 配置怎么读

[config.yaml](./config.yaml) 按四段组织：

```yaml
# 1. 哪个目录安装什么
install:
  "~/.agents/skills":
    preset: default

# 2. 哪些宿主安装原生扩展
extensions:
  ponytail:
    hosts: [codex, cursor]

# 3. 默认 Skill 集合
presets:
  default:
    sources: [unix2dos, ljg-skills, sepia]
    skills: [archify]

# 4. Skill 从哪里获取
sources:
  unix2dos:
    github: unix2dos/skills
    checkout: ~/workspace/skills
    exclude: [confidence-check, code-refactor, code-simplifier]

  ljg-skills:
    github: lijigang/ljg-skills
    skills_dir: skills
    include: [ljg-plain, ljg-think, ljg-writes, ljg-roundtable]

  sepia:
    github: Nanako0129/sepia
    skills_dir: skills

  archify:
    github: tt-a1i/archify
    skill: archify
```

解析顺序：

```text
仓库 → skills_dir/skill → include/exclude → Source → Preset → 安装目录
```

### Source 字段

| 字段 | 含义 |
|---|---|
| `github` | GitHub `owner/repo` |
| `checkout` | 自定义本地 checkout；默认 `~/.skills-community/<source>` |
| `skills_dir` | 从该路径发现一级 Skill 目录 |
| `skill` | 只提取一个 Skill 的精确路径 |
| `branch` | 分支或 tag；未填写时使用 `main` |
| `include` | 只保留这些 Skill |
| `exclude` | 排除这些 Skill |
| `build` | 更新后执行构建命令 |
| `runtime_assets` | 构建后链接到 Skill 的资源 |

Source 声明顺序也是同名 Skill 的优先级。只有被 Preset 或安装目录引用的 Source 才会聚合；未使用 Source 会出现在 Preview 中。

## 当前结果

`default` Preset 的实际 Skill 数量以 `bash install.sh --preview` 为准。Sepia 的相邻 Skill 会作为同一个 Source 分发，Archify 和 Show Me 也已包含在内。它们会安装到：

- `~/.claude/skills`
- `~/.cursor/skills`
- `~/.agents/skills`
- `~/.gemini/antigravity/skills`
- `~/.gemini/antigravity-cli/skills`
- `~/.config/opencode/skills`
- `~/.workbuddy/skills`

安装目录中的真实文件或真实 Skill 由外部管理，安装器会保留；受管 Skill 使用软链接直接指向 Source。

Sepia 当前只包含标准 Skill，因此通过 Source 安装，不另外注册原生 Extension。不要同时使用 Source 与 Codex 原生插件安装，以免重复暴露同名 Skill。

## Extension

Extension 配置按名字寻找 `installers/<name>.sh`，统一接收：

```bash
installers/ponytail.sh preview codex cursor
installers/ponytail.sh dry-run codex cursor
installers/ponytail.sh install codex cursor
```

当前 Ponytail 行为：

- Codex：安装完整插件；Hook 变化后在 `/hooks` 人工审查，并新建任务。
- Cursor：安装到 `~/.cursor/plugins/local/ponytail`，仅提供 always-on 规则；不含 Ponytail 模式、Hooks 和命令。安装后重启 Cursor 或执行 `Developer: Reload Window`。

新增 Extension 时，只需增加 `installers/<name>.sh` 并在 `config.yaml` 声明 Host。

## 云 Agent（bundle）

本地软链覆盖不了云上的 Agent（Devin 云会话、Claude Code 等）。`config.yaml` 的 `bundle` 段把 Preset 解析结果**复制**成标准 plugin 目录——真实文件而非软链，提交进 git 即可被云端引用：

```yaml
bundle:
  name: unix2dos-skills
  path: bundle        # 相对 skills-manager/；也支持 ~ 或绝对路径
  preset: default
```

`bash install.sh` 会重写 `bundle/skills/` 和两份 manifest（`.devin-plugin/plugin.json`、`.claude-plugin/plugin.json`）。日常维护不变：改 Skill 或 config → `install.sh` → 提交 bundle diff → push，云端安装自动跟上。

各平台装法：

- **Devin**：Settings → Customize → Plugins 安装 `https://github.com/unix2dos/dotfiles/tree/main/skills-manager/bundle`（支持 repo 子目录）
- **Claude Code**：`/plugin marketplace add unix2dos/dotfiles` → `/plugin install unix2dos-skills@unix2dos`（依赖仓库根目录的 `.claude-plugin/marketplace.json`）
- **其他**：任何支持 git plugin / marketplace 的 Agent 都指向同一 bundle 目录

注意：bundle 会把第三方 Source 的 Skill 一并复制进来。dotfiles 是公开仓库，等于在公开渠道再分发这些 Skill——上游均为公开仓库但建议自行确认其 License。介意的话把 `bundle.path` 指到一个私有仓库。
