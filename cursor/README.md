# Cursor CLI

This directory contains Cursor CLI configuration managed by the root
`install.sh`.

## Files

| File | Purpose |
|:-----|:--------|
| `statusline.sh` | Command used by Cursor's status line. |
| `cli-config.base.json` | Base Cursor CLI config merged into `~/.cursor/cli-config.json`. |

## Install Behavior

Running the root installer:

```bash
cd ~/workspace/dotfiles && ./install.sh
```

will:

- symlink `cursor/statusline.sh` to `~/.cursor/statusline.sh`
- make `cursor/statusline.sh` executable
- initialize `~/.cursor/cli-config.json` from `cursor/cli-config.base.json` when missing
- merge `cursor/cli-config.base.json` into an existing `~/.cursor/cli-config.json` when present

The merge requires `jq`. If `jq` is missing, the installer skips only the Cursor
CLI config merge.

## Status Line

`cli-config.base.json` configures Cursor to run:

```json
"statusLine": {
  "type": "command",
  "command": "~/.cursor/statusline.sh",
  "padding": 1,
  "updateIntervalMs": 500,
  "timeoutMs": 1500
}
```

The status line shows:

- current model name
- model parameters and MAX mode when available
- context usage as `total_input_tokens/context_window_size`
- context usage percentage
- usage bar
- remaining context percentage
- current project directory or worktree label

Keep Cursor-specific status-line details here instead of the root README.
