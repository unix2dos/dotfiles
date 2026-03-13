# Skills Install Layer Design

**Date:** 2026-03-13

## Context

`/Users/liuwei/workspace/skills` 当前同时承担了三种职责：

1. 自维护 skill 源码仓库
2. 第三方和生成型 skill 的安装入口
3. 多个平台的统一链接目标

这个角色混合会带来几个问题：

- 仓库内容不纯，`ls -al` 里大量是安装态软链接，不再像源码仓库
- 第三方来源和生成产物混入本地源码仓库，长期边界模糊
- `~/.agents/skills`、`~/.codex/skills` 等入口很难区分“真实来源”和“运行时聚合层”
- 软链接链路容易循环，排障成本高

## Goals

- 让 `/Users/liuwei/workspace/skills` 回归“自维护 skill 源码仓库”
- 不把 `superpowers`、`ed3d-*` 这类第三方或生成型 skill 直接放进源码仓库
- 用一个平台中立的安装聚合层统一管理运行时可见的 skills
- 用 `dotfiles` 中的脚本重建聚合层和消费入口
- 当前只覆盖真实在用的入口：`/Users/liuwei/.codex/skills` 和 `/Users/liuwei/.agents/skills`

## Non-Goals

- 不重写 `superpowers` 或 `compat-ed3d` 的内容
- 不把第三方 skill 源码复制进 `/Users/liuwei/workspace/skills`
- 不在本期纳入未确认实际在用的平台入口
- 不把运行时聚合层当成一个需要提交到 git 的源码仓库

## Options Considered

### Option A: Continue Using `/Users/liuwei/workspace/skills` as the Aggregation Layer

优点：

- 最少目录
- 历史兼容最好

缺点：

- 源码仓库和安装层继续混在一起
- 第三方和生成产物继续污染仓库边界
- 不符合“保持 skill 仓库纯净”的目标

结论：拒绝。

### Option B: Use `/Users/liuwei/.codex/skills` or `/Users/liuwei/.codex/skills-installed`

优点：

- 比 `workspace/skills` 更适合作为运行时目录
- 对 Codex 使用路径直观

缺点：

- 安装层名字依赖某个具体工具
- 难以表达“这是所有入口共享的运行时聚合层”

结论：比 Option A 好，但仍然过度绑定 Codex。

### Option C: Use `/Users/liuwei/.skills-installed`

优点：

- 语义中立，不依赖单个平台
- 清楚表达“这是安装聚合层”
- 能让 `~/.codex/skills`、`~/.agents/skills` 仅作为消费入口
- 更符合长期的分层设计

缺点：

- 不是现成的约定路径，需要自维护文档和脚本

结论：采用。

## Selected Architecture

### 1. Source Layer

`/Users/liuwei/workspace/skills`

职责：

- 只保留你自己长期维护、愿意纳入 git 的真实 skill 源码
- 不再保留 `superpowers`、`ed3d-*`、以及其他仅用于安装的第三方软链接

### 2. Upstream/Generated Source Layer

独立来源保留在各自原位：

- `/Users/liuwei/.codex/superpowers`
- `/Users/liuwei/workspace/compat-ed3d`

职责：

- 第三方和生成型 skill 的真实来源
- 不通过复制进入 `workspace/skills`

### 3. Install Layer

`/Users/liuwei/.skills-installed`

职责：

- 作为唯一运行时聚合目录
- 只存放可消费的 skill 入口
- 由 `dotfiles` 安装脚本重建，不手工长期维护

### 4. Consumer Layer

当前只覆盖两个入口：

- `/Users/liuwei/.codex/skills`
- `/Users/liuwei/.agents/skills`

职责：

- 作为工具读取 skills 的既有入口
- 最终都应指向 `/Users/liuwei/.skills-installed`

## Installer Ownership

安装编排逻辑放在 `/Users/liuwei/workspace/dotfiles`，不再放在 `workspace/skills`。

建议新增：

- `/Users/liuwei/workspace/dotfiles/codex/skills-install.sh`
- `/Users/liuwei/workspace/dotfiles/codex/skills-sources.sh`
- `/Users/liuwei/workspace/dotfiles/codex/README.md`

职责分工：

- `skills-sources.sh`：声明来源目录和启用规则
- `skills-install.sh`：备份旧入口，重建 `~/.skills-installed`，再重建消费入口
- `README.md`：解释架构、命令和新增来源方式

## Runtime Flow

1. 你在 `/Users/liuwei/workspace/skills` 维护自己的 skill 源码
2. `superpowers` 保持在 `/Users/liuwei/.codex/superpowers`
3. `ed3d-*` 保持在 `/Users/liuwei/workspace/compat-ed3d/targets/codex/skills`
4. 运行 `dotfiles` 中的 installer
5. installer 重建 `/Users/liuwei/.skills-installed`
6. installer 让 `~/.codex/skills`、`~/.agents/skills` 都指向这个聚合层

## Acceptance Criteria

1. `/Users/liuwei/workspace/skills` 中不再保留为安装而存在的 `superpowers` 软链接。
2. `/Users/liuwei/workspace/skills` 中不再保留为安装而存在的 `ed3d-*` 软链接。
3. `/Users/liuwei/workspace/skills` 中不再保留其他仅用于安装入口的第三方软链接。
4. `/Users/liuwei/workspace/skills` 仍然保留你自己的 skill 源码与必要仓库说明。
5. 新建 `/Users/liuwei/.skills-installed` 作为唯一安装聚合目录。
6. `/Users/liuwei/.codex/skills` 必须指向 `/Users/liuwei/.skills-installed`。
7. `/Users/liuwei/.agents/skills` 必须指向 `/Users/liuwei/.skills-installed`。
8. `superpowers` 相关 skill 在聚合层中仍然可用，并指向 `/Users/liuwei/.codex/superpowers` 下真实来源。
9. `ed3d-*` 相关 skill 在聚合层中仍然可用，并指向 `/Users/liuwei/workspace/compat-ed3d` 下真实来源。
10. 你自维护的本地 skill 在聚合层中仍然可用，并指向 `/Users/liuwei/workspace/skills` 下真实来源。
11. 整个链路中不存在循环软链接。
12. 切换前原有 `~/.codex/skills` 和 `~/.agents/skills` 有可恢复备份。
13. `dotfiles` 中存在一个可重复执行的脚本，用于重建 `/Users/liuwei/.skills-installed`。
14. 该脚本执行后，能够完整重建聚合层、`~/.codex/skills` 和 `~/.agents/skills`。
15. `dotfiles` 文档中明确说明架构分层、脚本职责、重建方式和新增来源方式。

## Rollout Notes

- 先补 installer 和文档，再切换本机实际入口
- 先重建聚合层，再修改 `~/.codex/skills` 和 `~/.agents/skills`
- 最后清理 `workspace/skills` 中历史遗留的安装态软链接

## Risks

- 如果直接删除旧入口而没有备份，容易丢失当前可用状态
- 如果 installer 不做去重和冲突处理，多个来源同名 skill 会互相覆盖
- 如果 `workspace/skills` 清理顺序不对，可能暂时影响当前工具发现 skill

## Open Questions

- 当前是否还有除 Codex 和 agents 之外的实际消费入口需要纳入 v1
- 多来源同名 skill 的优先级是否固定为“本地源码 > 生成来源 > 第三方来源”
