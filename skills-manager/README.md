# Agent Skills

管理多个 AI 工具（Claude / Codex / Gemini / OpenCode 等）的 skills 统一安装层。

Unified skills installation layer for multiple AI tools (Claude / Codex / Gemini / OpenCode, etc.)

---

## 目录 / Contents

- [快速开始 / Quick Start](#快速开始--quick-start)
- [安装来源 A：unix2dos/skills](#安装来源-aunix2dosskills)
- [安装来源 B：obra/superpowers](#安装来源-bobrасупerpowers)
- [自定义来源路径 / Custom Source Paths](#自定义来源路径--custom-source-paths)
- [运行安装脚本 / Run Installer](#运行安装脚本--run-installer)
- [验证安装 / Verify](#验证安装--verify)
- [附录：架构说明 / Appendix: Architecture](#附录架构说明--appendix-architecture)

---

## 快速开始 / Quick Start

> 按需 clone 一个或两个来源，然后运行安装脚本即可。
>
> Clone one or both sources as needed, then run the installer.

```bash
# 1. Clone 来源（按需选择）/ Clone sources (pick what you need)
git clone https://github.com/unix2dos/skills.git ~/workspace/skills
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers

# 2. 运行安装脚本 / Run installer
bash ~/workspace/dotfiles/agent-skills/install.sh
```

完成。Skills 已自动链接到所有 AI 工具的入口目录。

Done. Skills are automatically linked to all AI tool directories.

---

## 安装来源 A：unix2dos/skills

你自己维护的 skills 仓库，优先级最高。

Your own skills repo — highest priority.

### 默认路径 / Default path

`sources.sh` 已预配置路径为 `~/workspace/skills`，直接 clone 即可：

`sources.sh` is pre-configured with `~/workspace/skills`. Just clone:

```bash
git clone https://github.com/unix2dos/skills.git ~/workspace/skills
```

然后运行安装脚本 / Then run the installer:

```bash
bash ~/workspace/dotfiles/agent-skills/install.sh
```

### 自定义路径 / Custom path

如需 clone 到其他位置，参见[自定义来源路径](#自定义来源路径--custom-source-paths)。

To clone elsewhere, see [Custom Source Paths](#自定义来源路径--custom-source-paths).

---

## 安装来源 B：obra/superpowers

第三方 skills 框架，优先级低于来源 A（同名 skill 以 A 为准）。

Third-party skills framework — lower priority than source A (source A wins on name conflicts).

### 默认路径 / Default path

`sources.sh` 已预配置路径为 `~/.codex/superpowers/skills`，直接 clone 即可：

`sources.sh` is pre-configured with `~/.codex/superpowers/skills`. Just clone:

```bash
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
```

然后运行安装脚本 / Then run the installer:

```bash
bash ~/workspace/dotfiles/agent-skills/install.sh
```

### 自定义路径 / Custom path

如需 clone 到其他位置，参见[自定义来源路径](#自定义来源路径--custom-source-paths)。

To clone elsewhere, see [Custom Source Paths](#自定义来源路径--custom-source-paths).

---

## 自定义来源路径 / Custom Source Paths

两个来源的路径均支持通过环境变量覆盖，无需修改 `sources.sh`：

Both source paths can be overridden via environment variables without editing `sources.sh`:

| 变量 / Variable | 默认值 / Default | 对应来源 / Source |
|---|---|---|
| `OWNED_SKILLS_ROOT` | `~/workspace/skills` | unix2dos/skills |
| `THIRD_PARTY_SKILLS_ROOT` | `~/.codex/superpowers/skills` | obra/superpowers |

示例 / Example:

```bash
# 将 unix2dos/skills clone 到自定义路径
git clone https://github.com/unix2dos/skills.git /your/custom/path

# 运行时指定路径
OWNED_SKILLS_ROOT=/your/custom/path bash ~/workspace/dotfiles/agent-skills/install.sh
```

如需永久修改默认路径，直接编辑 `sources.sh` 中的 `DEFAULT_OWNED_SKILLS_ROOT` 或 `DEFAULT_THIRD_PARTY_SKILLS_ROOT`。

To permanently change defaults, edit `DEFAULT_OWNED_SKILLS_ROOT` or `DEFAULT_THIRD_PARTY_SKILLS_ROOT` in `sources.sh`.

---

## 运行安装脚本 / Run Installer

每次 clone 新来源或更新来源后，重新运行安装脚本：

Re-run the installer after cloning a new source or pulling updates:

```bash
bash ~/workspace/dotfiles/agent-skills/install.sh
```

脚本会自动完成 / The script automatically:

1. 重建 `~/.skills-installed`，按优先级聚合所有来源 / Rebuilds `~/.skills-installed`, merging all sources by priority
2. 将所有 AI 工具的 skills 入口指向统一目录 / Points all AI tool skill entries to the unified directory

---

## 验证安装 / Verify

```bash
# 查看已安装的 skills 列表 / List installed skills
ls ~/.skills-installed

# 确认 Claude 入口已链接 / Confirm Claude entry is linked
ls -la ~/.claude/skills
```

预期输出 / Expected output:

```
~/.claude/skills -> ~/.skills-installed
```

---

## 附录：架构说明 / Appendix: Architecture

| 层 / Layer | 路径 / Path | 说明 / Description |
|---|---|---|
| 来源层 / Sources | `~/workspace/skills`, `~/.codex/superpowers/skills` | 各自独立维护的 skill 仓库 |
| 安装层 / Installed | `~/.skills-installed` | 运行时聚合目录，同名取高优先级 |
| 消费层 / Consumers | `~/.claude/skills`, `~/.codex/skills`, 等 | AI 工具读取入口，均软链接到安装层 |

来源优先级：`unix2dos/skills` > `obra/superpowers`（同名 skill 以前者为准）

Source priority: `unix2dos/skills` > `obra/superpowers` (former wins on conflicts)

### 新增来源 / Adding a new source

1. 编辑 `sources.sh`，在 `SKILL_SOURCE_LABELS` 和 `SKILL_SOURCE_PATHS` 数组中追加同索引项
2. 重新运行安装脚本

---

1. Edit `sources.sh`, append a matching entry to both `SKILL_SOURCE_LABELS` and `SKILL_SOURCE_PATHS` arrays
2. Re-run the installer
