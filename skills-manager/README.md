# Skills Manager

多 AI 工具的全局 skills 聚合安装层。

## 快速开始

```bash
# 1. 按需 clone 来源（可只选其一）
git clone https://github.com/unix2dos/skills.git ~/workspace/skills
git clone https://github.com/obra/superpowers.git ~/.codex/superpowers

# 2. 安装
bash ~/workspace/dotfiles/skills-manager/install.sh

# 3. 验证
ls -la ~/.claude/skills   # 预期：~/.claude/skills -> ~/.skills-installed
```

---

## 来源

### A：unix2dos/skills（优先级 1）

自有 skills 仓库。

```bash
git clone https://github.com/unix2dos/skills.git ~/workspace/skills
```

### B：obra/superpowers（优先级 2）

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
| `THIRD_PARTY_SKILLS_ROOT` | `~/.codex/superpowers/skills` | obra/superpowers |

---

## 附录：架构

| 层 | 路径 | 说明 |
|---|---|---|
| 来源层 | `~/workspace/skills`, `~/.codex/superpowers/skills` | 独立维护的 skill 仓库 |
| 安装层 | `~/.skills-installed` | 聚合目录，同名取高优先级 |
| 消费层 | `~/.claude/skills`, `~/.codex/skills` 等 | AI 工具入口，软链接到安装层 |

来源优先级：A > B，同名 skill 以 A 为准。
