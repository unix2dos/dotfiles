# Skills Manager

多 AI 工具的全局 skills 聚合安装层。

## 快速开始

```bash
bash ~/workspace/dotfiles/skills-manager/install.sh
```

一条命令搞定：克隆所有来源 → 拉取外部资源 → 聚合分发到所有 AI 工具。

## 文件说明

| 文件 | 什么时候改 |
|---|---|
| `sources.sh` | 加来源、调优先级顺序 |
| `fetch.sh` | 加/删要拉取的外部 skill 仓库 |
| `link.sh` | 加/删 AI 工具消费入口 |
| `install.sh` | 一般不用改，一键运行入口 |

## 来源（按优先级从高到低）

| 优先级 | 来源 | 仓库 | 安装方式 |
|--------|------|------|----------|
| 1 | owned | unix2dos/skills | git clone |
| 2 | superpowers | obra/superpowers | git clone |
| 3 | gstack | garrytan/gstack | git clone + bun build |
| 4 | community | 多个 GitHub 仓库 | clone + rsync 提取 |

同名 skill 以高优先级为准。

## 单独运行子步骤

```bash
# 只拉取/更新外部 skills（gstack + 社区）
bash ~/workspace/dotfiles/skills-manager/fetch.sh

# 只重新聚合分发（不拉取）
bash ~/workspace/dotfiles/skills-manager/link.sh

# 预览模式
bash ~/workspace/dotfiles/skills-manager/install.sh --dry-run
```

## 自定义路径

通过环境变量覆盖，无需修改 `sources.sh`：

| 变量 | 默认值 | 来源 |
|---|---|---|
| `OWNED_SKILLS_ROOT` | `~/workspace/skills` | unix2dos/skills |
| `SUPERPOWERS_SKILLS_ROOT` | `~/.skills-community/superpowers/skills` | obra/superpowers |
| `GSTACK_SKILLS_ROOT` | `~/.skills-community/gstack/.agents/skills` | garrytan/gstack |
| `COMMUNITY_SKILLS_ROOT` | `~/.skills-community` | 社区 skill 收藏 |
