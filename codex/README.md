# Codex Skills Install Layer

This directory owns the runtime skill install process for the current machine.

## Architecture

There are four layers:

1. Source layer: `/Users/liuwei/workspace/skills`
2. Third-party/generated sources:
   - `/Users/liuwei/.codex/superpowers`
   - `/Users/liuwei/workspace/compat-ed3d`
3. Runtime install layer: `/Users/liuwei/.skills-installed`
4. Consumer entrypoints:
   - `/Users/liuwei/.codex/skills`
   - `/Users/liuwei/.agents/skills`

`/Users/liuwei/workspace/skills` is treated as the owned source repository only. It should not carry `superpowers`, `ed3d-*`, or other runtime-only symlink entries.

## Files

- `skills-sources.sh`: declares enabled skill source roots in priority order
- `skills-install.sh`: rebuilds `/Users/liuwei/.skills-installed` and repoints active consumers
- `test-skills-install.sh`: verifies manifest ordering, install behavior, and docs coverage

## Source Priority

The installer resolves duplicate names with this priority:

1. owned source
2. generated source
3. third-party source

The first hit wins.

## Install

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/codex/skills-install.sh
```

This will:

1. rebuild `/Users/liuwei/.skills-installed`
2. back up the current `~/.codex/skills` and `~/.agents/skills`
3. repoint both entrypaths to `/Users/liuwei/.skills-installed`

Backups are created as timestamped paths, and a stable `.backup` symlink is updated to point at the latest backup.

## Test

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/codex/test-skills-install.sh
```

## How to add a new source

To add a new source:

1. decide whether it is owned, generated, or third-party
2. extend `skills-sources.sh` with the new source root and desired priority
3. update `test-skills-install.sh` if the source changes install behavior
4. rerun the installer and tests

Keep real content in its own repository or generated output directory. Only the runtime install layer should aggregate sources.
