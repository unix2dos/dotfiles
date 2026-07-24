# Skills Manager

多 AI 工具的 skill 聚合层。**core** = 默认装进 Cursor / Claude / Codex 等工具的 skill 集（含 `mattpocock/skills` 的 engineering + productivity；in-progress 仅按需安装）。

安装与配置 → [INSTALL.md](./INSTALL.md)

---

## 怎么用：按阶段找 skill

| 阶段 | 组 | 干什么 | 代表 skill |
|---|---|---|---|
| 还没说清楚要做什么 | ① 澄清 | 挖意图、对齐需求、grilling 方案 | ask-first, grill-with-docs, grill-me |
| 要定架构或方向 | ② 设计 | 系统设计、画图、UI 审计、产品战略 | architecture-designer, mermaid-generator |
| 要写/改代码 | ③ 编码 | Go 重构、简化代码、疑难诊断 | code-refactor, code-simplifier |
| 要产出内容 | ④ 写作 | 博客、润色、去 AI 味、深度长文 | blog-knowledge-extraction, ljg-writes |
| 要系统学一个主题 | ⑤ 学习 | 生成学习地图、分阶段讲解 | learn-map |
| 要管理 skill 本身 | ⑥ 元工具 | 发现、自动优化 skill | find-skills, autoresearch |
| 工程流程（Matt Pocock） | ⑦ 工程 | 诊断、TDD、拆 issue、PRD、triage | diagnosing-bugs, tdd, to-issues, triage |
| 实验性（Matt Pocock，非 core） | ⑧ 实验 | 决策地图、workflow 设计、双轴 review、写作 shaping | decision-mapping, loop-me, review, writing-shape |

> **触发：** `自动` = agent 自行判断；`手动 @` = 需显式说出触发词（如 `@ui-ux-auditor`）。

---

## ① 澄清与方案对齐

任务没说清、方案没对齐时先用这组。

| Skill | 干什么 | 触发 |
|---|---|---|
| ask-first | 从模糊/类比/情绪化输入照见真实意图 | 自动 |
| grill-with-docs | 逐题 grilling 方案，更新 CONTEXT.md / ADR | 自动 |
| grill-me | 逐题 grilling（无 repo 文档时） | 自动 |
| handoff | 压缩会话为交接文档 | 自动 |

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
| code-refactor | Go 代码重构（SOLID、idiomatic Go） | 自动 |
| code-simplifier | 简化代码、降复杂度 | 自动 |
| diagnosing-bugs | 疑难 bug / 性能回归诊断循环 | 自动 |
| tdd | 红绿重构 TDD | 自动 |
| triage | Issue 分诊状态机 | 自动 |
| to-issues | 计划拆成可独立领取的 GitHub issues | 自动 |
| to-prd | 对话上下文 → PRD issue | 自动 |
| prototype | 可抛原型验证设计 | 自动 |
| improve-codebase-architecture | 结合 CONTEXT/ADR 找架构深化点 | 自动 |
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
| find-skills | 搜索安装社区 skill | 自动 |
| autoresearch | 自动 eval + 优化 skill prompt | 手动 @ |
| dedup-history | 为每日/随机内容生成类 skill 提供历史去重 | 子 Skill（手动） |
| writing-great-skills | 按 Matt Pocock 结构写新 skill | 自动 |

> Codex 自带的 `.system/skill-creator` 由 Codex 管理，不进入本项目的 source 或 core。

## ⑧ Matt Pocock · in-progress（实验性，非 core）

上游 `skills/in-progress`，API 可能变动；保留为可选 source，不随 core 默认安装。

| Skill | 干什么 | 触发 |
|---|---|---|
| decision-mapping | 松散想法 → 决策地图 + 逐 ticket 推进 | 手动 |
| loop-me | grilling 产出 workflow spec | 手动 |
| review | 双轴 review（Standards + Spec），并行 sub-agent | 自动 |
| writing-fragments | grilling 挖掘写作碎片，沉淀 raw material | 自动 |
| writing-shape | 把 notes/碎片对话式塑造成可发布文章 | 自动 |
| writing-beats | 选 beat 逐段写，CYOA 式叙事 | 自动 |

---

## 边界说明

- **unix2dos/skills** 当前整源进入 core，触发方式由各 Skill 的 `agents/openai.yaml` 控制
- **Matt Pocock in-progress** 仍聚合为可选 source，但不进入 core
- **ljg-skills** 只稀疏检出并聚合 `ljg-plain`、`ljg-think`、`ljg-writes`、`ljg-roundtable`
- **Superpowers** source 已移除，不再下载或分发

完整 source 列表、非 core skill 明细、安装命令 → [INSTALL.md](./INSTALL.md)
