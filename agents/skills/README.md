# Agent Skills 运行时安装层

这个目录负责管理本机的 agent skills 运行时安装层。

## 架构分层

当前采用四层结构：

1. 源码层：`/Users/liuwei/workspace/skills`
2. 第三方/生成来源层：
   - `/Users/liuwei/.codex/superpowers`
   - `/Users/liuwei/workspace/compat-ed3d`
3. 运行时安装层：`/Users/liuwei/.skills-installed`
4. 消费入口层：
   - `/Users/liuwei/.agents/skills`
   - `/Users/liuwei/.claude/skills`
   - `/Users/liuwei/.codex/skills`
   - `/Users/liuwei/.config/opencode/skills`
   - `/Users/liuwei/.config/alma/skills`
   - `/Users/liuwei/.gemini/antigravity/skills`
   - `/Users/liuwei/.openclaw/skills`

`/Users/liuwei/workspace/skills` 只负责维护你自己的 skills 源码，不应该再承载 `superpowers`、`ed3d-*` 或其他仅用于运行时聚合的软链接入口。

## 文件说明

- `sources.sh`：声明启用的来源目录和优先级
- `install.sh`：重建 `/Users/liuwei/.skills-installed`，并重定向当前消费入口
- `test-install.sh`：验证来源顺序、安装行为和文档引用

## 来源优先级

同名 skill 按下面的优先级取第一个命中项：

1. owned source
2. generated source
3. third-party source

## 安装

执行：

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/install.sh
```

这个脚本会：

1. 重建 `/Users/liuwei/.skills-installed`
2. 备份当前的各个 skills 消费入口
3. 把下面这些入口统一指向 `/Users/liuwei/.skills-installed`

- `~/.agents/skills`
- `~/.claude/skills`
- `~/.codex/skills`
- `~/.config/opencode/skills`
- `~/.config/alma/skills`
- `~/.gemini/antigravity/skills`
- `~/.openclaw/skills`

备份会以时间戳命名，同时更新稳定的 `.backup` 软链接，指向最近一次备份。

## 测试

执行：

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

## 如何新增来源

新增来源时按这个顺序处理：

1. 先决定它属于 owned、generated 还是 third-party
2. 在 `sources.sh` 里补充来源目录和优先级
3. 如果安装行为发生变化，同步更新 `test-install.sh`
4. 重新运行安装脚本和测试

真实内容应继续保留在各自的仓库或生成目录中，`/Users/liuwei/.skills-installed` 只负责运行时聚合。
