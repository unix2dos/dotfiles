# Skills Manager

多 AI 工具的全局 skills 聚合安装层。

## 快速开始

```bash
# 1. 按需 clone 来源
git clone https://github.com/unix2dos/skills.git ~/workspace/skills

# 2. 拉取社区 skills
bash ~/workspace/dotfiles/skills-manager/update-community.sh

# 3. 安装（聚合 + 分发）
bash ~/workspace/dotfiles/skills-manager/install.sh

# 4. 验证
ls -la ~/.claude/skills   # 预期：~/.claude/skills -> ~/.skills-installed
```

---

## 来源

### A：unix2dos/skills（优先级 1）

自有 skills 仓库。

```bash
git clone https://github.com/unix2dos/skills.git ~/workspace/skills
```

### B：社区 skills（优先级 2）

收藏的社区 skills，由 `update-community.sh` 从各 GitHub 仓库拉取到 `~/.skills-community/`。

```bash
# 拉取/更新社区 skills
bash ~/workspace/dotfiles/skills-manager/update-community.sh

# 仅预览变更
bash ~/workspace/dotfiles/skills-manager/update-community.sh --dry-run
```

### C：obra/superpowers（优先级 3）

第三方 skills 框架。

```bash
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
```

clone 完成后重新运行 `install.sh` 生效。

---

## 自定义路径

通过环境变量覆盖，无需修改 `sources.sh`：

| 变量 | 默认值 | 来源 |
|---|---|---|
| `OWNED_SKILLS_ROOT` | `~/workspace/skills` | unix2dos/skills |
| `COMMUNITY_SKILLS_ROOT` | `~/.skills-community` | 社区 skill 收藏 |
| `THIRD_PARTY_SKILLS_ROOT` | `~/.codex/superpowers/skills` | obra/superpowers |

---

## 附录：架构

| 层 | 路径 | 说明 |
|---|---|---|
| 来源层 | `~/workspace/skills` | 自有 skill 源码 |
| 来源层 | `~/.skills-community` | 收藏的社区 skill |
| 来源层 | `~/.codex/superpowers/skills` | 第三方 skill 框架 |
| 安装层 | `~/.skills-installed` | 聚合目录，同名取高优先级 |
| 消费层 | `~/.claude/skills`, `~/.codex/skills` 等 | AI 工具入口，软链接到安装层 |

来源优先级：A > B > C，同名 skill 以高优先级为准。
