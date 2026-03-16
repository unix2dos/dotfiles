# AI Kit

项目级 AI 工具安装器。自动检测已安装的 AI 工具并完成配置。

## 使用

```bash
bash ~/workspace/dotfiles/ai-kit/install.sh
```

---

## 工具

| 工具 | 说明 | 安装 |
|---|---|---|
| [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | UI/UX 设计智能（67 种风格、161 配色、57 字体） | 自动 |
| [ed3d-plugins](https://github.com/ed3dai/ed3d-plugins) | RPI 规划工作流，9 个插件 | 手动，见下方 |
| [claude-skills](https://github.com/Jeffallan/claude-skills) | 全栈开发技能集，66 个技能 | 手动，见下方 |

---

## 手动安装（在 Claude Code 内执行）

**ed3d-plugins**

```
/plugin marketplace add https://github.com/ed3dai/ed3d-plugins.git
/plugin install ed3d-plan-and-execute@ed3d-plugins
```

**claude-skills**

```
/plugin marketplace add jeffallan/claude-skills
/plugin install fullstack-dev-skills@jeffallan
```
