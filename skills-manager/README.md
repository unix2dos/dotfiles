# Skills Manager

多 AI 工具的 skill 聚合层。**core** = 默认装进 Cursor / Claude / Codex 等工具的 skill 集（含 `mattpocock/skills` 的 engineering + productivity 全套）。

安装与配置 → [INSTALL.md](./INSTALL.md)

---

## 怎么用：按阶段找 skill

| 阶段 | 组 | 干什么 | 代表 skill |
|---|---|---|---|
| 还没说清楚要做什么 | ① 澄清 | 挖意图、对齐需求、grilling 方案 | ask-first, grill-with-docs, grill-me |
| 要定架构或方向 | ② 设计 | 系统设计、画图、UI 审计、产品战略 | architecture-designer, mermaid-generator |
| 要写/改代码 | ③ 编码 | 编码守则、Go 重构、简化代码 | karpathy-guidelines, code-refactor |
| 要产出内容 | ④ 写作 | 博客、润色、去 AI 味、深度长文 | blog-knowledge-extraction, ljg-writes |
| 要系统学一个主题 | ⑤ 学习 | 生成学习地图、分阶段讲解 | learn-map |
| 要管理 skill 本身 | ⑥ 元工具 | 创建、发现、自动优化 skill | skill-creator, autoresearch |
| 工程流程（Matt Pocock） | ⑦ 工程 | 诊断、TDD、拆 issue、PRD、triage | diagnose, tdd, to-issues, triage |

> **触发：** `自动` = agent 自行判断；`手动 @` = 需显式说出触发词（如 `@ui-ux-auditor`）。

---

## ① 澄清与方案对齐

任务没说清、方案没对齐时先用这组。

| Skill | 干什么 | 触发 |
|---|---|---|
| ask-first | 从模糊/类比/情绪化输入照见真实意图 | 自动 |
| asking-clarifying-questions | 动手前对齐需求、消歧术语、验证假设 | 自动 |
| grill-with-docs | 逐题 grilling 方案，更新 CONTEXT.md / ADR | 自动 |
| grill-me | 逐题 grilling（无 repo 文档时） | 自动 |
| handoff | 压缩会话为交接文档 | 自动 |
| caveman | 极简沟通模式 | 自动 |
| confidence-check | 写代码前做前置信度检查 | 自动 |

## ② 架构与设计

| Skill | 干什么 | 触发 |
|---|---|---|
| architecture-designer | 系统架构设计、ADR、技术选型 | 自动 |
| mermaid-generator | 生成 Mermaid 流程图/时序图/ER 图 | 自动 |
| ui-ux-auditor | UI/UX 设计审计 | 手动 @ |
| strategic-product-advisor | 产品方向、竞品、商业模式 | 手动 @ |

## ③ 编码

| Skill | 干什么 | 触发 |
|---|---|---|
| karpathy-guidelines | LLM 编码守则（少过度设计、surgical 改动） | 自动 |
| code-refactor | Go 代码重构（SOLID、idiomatic Go） | 自动 |
| code-simplifier | 简化代码、降复杂度 | 自动 |
| diagnose | 疑难 bug / 性能回归诊断循环 | 自动 |
| tdd | 红绿重构 TDD | 自动 |
| triage | Issue 分诊状态机 | 自动 |
| to-issues | 计划拆成可独立领取的 GitHub issues | 自动 |
| to-prd | 对话上下文 → PRD issue | 自动 |
| prototype | 可抛原型验证设计 | 自动 |
| improve-codebase-architecture | 结合 CONTEXT/ADR 找架构深化点 | 自动 |
| zoom-out | 拉高视角理解陌生代码 | 自动 |
| setup-matt-pocock-skills | 脚手架 `docs/agents/` 等工程 skill 配置 | 手动 |

## ④ 内容与写作

| Skill | 干什么 | 触发 |
|---|---|---|
| blog-knowledge-extraction | 素材 → 中文技术博客 | 手动 @ |
| technical-content-optimizer | 博客润色到工程博客水准 | 手动 @ |
| humanizer-zh | 去除中文 AI 写作痕迹 | 自动 |
| ljg-plain | 白话解释，说人话 | 自动 |
| ljg-think | 纵向深钻，追到本质 | 自动 |
| ljg-writes | 深度长文（1000–1500 字） | 自动 |
| ljg-roundtable | 多视角圆桌辩论 | 自动 |

## ⑤ 学习与探索

| Skill | 干什么 | 触发 |
|---|---|---|
| learn-map | 系统化学习一个主题 | 手动 @ |

## ⑥ Skill 生态

| Skill | 干什么 | 触发 |
|---|---|---|
| skill-creator | 创建/修改 skill、跑 eval | 自动 |
| find-skills | 搜索安装社区 skill | 自动 |
| autoresearch | 自动 eval + 优化 skill prompt | 自动 |
| write-a-skill | 按 Matt Pocock 结构写新 skill | 自动 |

---

## 不在 core 里？

- **Codex** 额外装了 `superpowers` 工程流程全家桶
- **OpenClaw** 额外装了 `skills` 仓库全部 skill（含 `go-code-review`、`daily-tech-digest` 等）
- **ljg-skills** 还有拆书、铸图、读论文等 15 个 skill 未进 core

完整 source 列表、非 core skill 明细、安装命令 → [INSTALL.md](./INSTALL.md)
