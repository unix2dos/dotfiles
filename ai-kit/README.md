# AI Kit

项目级 AI 工具安装器。在新项目中一键安装 AI 辅助工具。

Project-level AI tools installer. One command to set up AI tools in a new project.

---

## 目录 / Contents

- [使用方式 / Usage](#使用方式--usage)
- [工具列表 / Tools](#工具列表--tools)
- [与 skills-manager 的区别 / vs skills-manager](#与-skills-manager-的区别--vs-skills-manager)

---

## 使用方式 / Usage

在项目根目录下执行 / Run in your project root:

```bash
bash ~/workspace/dotfiles/ai-kit/install.sh
```

或按需单独安装某个工具 / Or install individual tools:

```bash
# ui-ux-pro-max
npm install -g uipro-cli && uipro init --ai claude
```

---

## 工具列表 / Tools

### ui-ux-pro-max-skill

专业 UI/UX 设计智能工具。安装后 Claude 可访问完整的设计知识库：67 种 UI 风格、161 个配色方案、57 种字体配对、161 条行业设计规则。

Professional UI/UX design intelligence. Gives Claude access to a full design knowledge base: 67 UI styles, 161 color palettes, 57 font pairings, 161 industry design rules.

| 项目 | 值 |
|---|---|
| 仓库 | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill |
| 安装方式 | `npm install -g uipro-cli && uipro init --ai claude` |
| 安装粒度 | per-project |
| 更新方式 | `uipro update` |

**适用场景：** 需要构建有设计感的 UI 的项目（网站、Landing Page、Dashboard、移动端）。

**When to use:** Projects that need professionally designed UI (websites, landing pages, dashboards, mobile apps).

---

## 与 skills-manager 的区别 / vs skills-manager

| | [skills-manager](../skills-manager/) | ai-kit |
|---|---|---|
| 安装粒度 | 全局（所有项目共享）| 项目级（每个项目独立）|
| 内容 | SKILL.md 指令文件 | 数据文件 + 脚本 + 指令 |
| 典型工具 | obra/superpowers, unix2dos/skills | ui-ux-pro-max-skill |
| 安装方式 | git clone + install.sh | CLI 工具（npm/pip 等）|
