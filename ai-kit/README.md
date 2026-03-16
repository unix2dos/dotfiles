# AI Kit

项目级 AI 工具安装器。在项目目录下运行，自动检测已安装的 AI 工具并完成配置。

Project-level AI tools installer. Run in any project directory — auto-detects your AI tools and installs accordingly.

---

## 使用方式 / Usage

```bash
bash ~/workspace/dotfiles/ai-kit/install.sh
```

脚本结束后会打印摘要：已安装、已跳过（未检测到）、需手动操作的工具。

After completion, a summary shows: installed, skipped (not detected), and tools requiring manual steps.

---

## 工具索引 / Tool Index

| 工具 | 用途 | 支持平台 | 安装方式 | 可脚本化 |
|---|---|---|---|---|
| [ui-ux-pro-max-skill](#ui-ux-pro-max-skill) | UI/UX 设计智能 | Claude / Cursor / Codex / Antigravity | CLI (`uipro`) | ✅ 自动 |
| [ed3d-plugins](#ed3d-plugins) | RPI 规划工作流 | Claude Code | `/plugin install` | ❌ 手动 |
| [claude-skills](#claude-skills) | 全栈开发专家技能集 | Claude Code | `/plugin install` | ❌ 手动 |

---

## 自动安装 / Automated

### ui-ux-pro-max-skill

专业 UI/UX 设计智能工具。给 AI 配备完整设计知识库：67 种 UI 风格、161 个配色方案、57 种字体配对、161 条行业设计规则。

Professional UI/UX design intelligence. Equips AI with a full design knowledge base: 67 UI styles, 161 color palettes, 57 font pairings, 161 industry design rules.

- **仓库 / Repo:** https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- **安装粒度 / Scope:** per-project
- **更新 / Update:** `uipro update`

**安装路径 / Install paths:**

| 平台 | 路径 |
|---|---|
| Claude Code | `.claude/skills/ui-ux-pro-max/` |
| Cursor | `.cursor/commands/ui-ux-pro-max.md` + `.shared/` |
| Codex | `.codex/skills/ui-ux-pro-max/` |
| Antigravity | `.agent/skills/ui-ux-pro-max/` |

**适用场景 / When to use:** 需要构建有设计感 UI 的项目（网站、Landing Page、Dashboard、移动端）。

---

## 手动安装 / Manual

以下工具需在 Claude Code 内执行 `/plugin` 命令安装，无法通过 bash 脚本自动化。

The following tools require `/plugin` commands inside Claude Code and cannot be automated via bash.

### ed3d-plugins

研究-规划-实现（RPI）工作流，包含 9 个插件，降低 AI 幻觉、确保高质量交付。

Research-Plan-Implement (RPI) workflow with 9 plugins to minimize hallucination and ensure quality.

- **仓库 / Repo:** https://github.com/ed3dai/ed3d-plugins
- **支持平台 / Platform:** Claude Code only

在 Claude Code 内执行 / Run inside Claude Code:

```
/plugin marketplace add https://github.com/ed3dai/ed3d-plugins.git
/plugin install ed3d-plan-and-execute@ed3d-plugins
```

---

### claude-skills

66 个专业技能 + 9 个工作流命令，覆盖全栈开发各领域（语言、框架、后端、前端、测试、安全、DevOps、数据/ML）。

66 specialized skills + 9 workflow commands covering full-stack development (languages, frameworks, backend, frontend, testing, security, DevOps, data/ML).

- **仓库 / Repo:** https://github.com/Jeffallan/claude-skills
- **支持平台 / Platform:** Claude Code only

在 Claude Code 内执行 / Run inside Claude Code:

```
/plugin marketplace add jeffallan/claude-skills
/plugin install fullstack-dev-skills@jeffallan
```

---

## 与 skills-manager 的区别 / vs skills-manager

| | [skills-manager](../skills-manager/) | ai-kit |
|---|---|---|
| 安装粒度 | 全局（所有项目共享）| 项目级（每个项目独立）|
| 典型内容 | SKILL.md 纯指令文件 | 数据文件 + 脚本 + 指令 |
| 典型工具 | obra/superpowers, unix2dos/skills | ui-ux-pro-max-skill |
| 安装方式 | git clone + install.sh | CLI 工具 / 插件市场 |
