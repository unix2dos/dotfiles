# Skills Manager

Multi-AI-tool skills aggregation layer.

## Quick Start

```bash
bash ~/workspace/dotfiles/skills-manager/install.sh
```

## Files

| File | Purpose |
|---|---|
| `sources.yaml` | All config: sources, priorities, repos, consumers |
| `install.sh` | All logic: clone → build → aggregate → link |

Edit `sources.yaml`, run `install.sh`.

## Sources (priority high → low)

| # | Name | Repo | Install |
|---|------|------|---------|
| 1 | owned | unix2dos/skills | git clone |
| 2 | superpowers | obra/superpowers | git clone |
| 3 | gstack | garrytan/gstack | git clone + bun build |
| 4 | community | multiple repos | clone + rsync extract |

Same-name skill → higher priority wins.
