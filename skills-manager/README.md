# Skills Manager

用一份配置把 Agent Skills 分发到多个 AI 工具，并安装 Ponytail 这类宿主原生扩展。

## 文件

```text
skills-manager/
├── README.md
├── config.yaml
├── install.sh
└── installers/
    └── ponytail.sh
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
    sources: [unix2dos, ljg-skills]
    skills: [archify, humanizer-zh]

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

  archify:
    github: tt-a1i/archify
    skills_dir: .
    include: [archify]
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

`default` Preset 当前包含 59 个 Skill，Archify 已包含在内。它分发到：

- `~/.claude/skills`
- `~/.cursor/skills`
- `~/.agents/skills`
- `~/.gemini/antigravity-cli/skills`
- `~/.config/opencode/skills`
- `~/.workbuddy/skills`

安装目录中的真实文件或真实 Skill 由外部管理，安装器会保留；受管 Skill 使用软链接直接指向 Source。

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
