# tmux

This directory contains the local tmux configuration layer and helper scripts.

The setup is based on [gpakosz/.tmux](https://github.com/gpakosz/.tmux), also
known as Oh My Tmux. The upstream template provides most default behavior,
theme variables, plugin bootstrapping, and baseline key bindings. This repo
keeps user-specific overrides in `tmux/.tmux.conf.local`.

## Configuration Model

### Upstream Layer: Oh My Tmux

Oh My Tmux owns the general tmux framework:

- `tmux_conf_*` variables for theme, status line, clipboard, plugin lifecycle,
  and session/window/pane behavior.
- Default key binding conventions.
- TPM-compatible plugin declaration style through `set -g @plugin ...`.
- Status-line expansion helpers used by the theme.

When changing broad tmux behavior, prefer adjusting the existing
`tmux_conf_*` variables before adding raw tmux commands. They are the intended
Oh My Tmux customization surface.

### Local Layer: `.tmux.conf.local`

The local override file adds this machine's workflow:

- Prefix is `Ctrl+a`.
- Status bar is shown at the top.
- Mouse support is enabled.
- Vi keys are used in status and copy mode.
- Copy-mode `t/T` jump prompts are disabled to avoid accidental yellow
  `(jump to forward)` prompts.
- `Cmd+o` is captured through a tmux `user-keys` entry and routed to
  `smart-open.sh`.
- `M-p`, `M-q`, and `M-w` are custom no-prefix popup workflows.
- Network speed, mode indicator, and session state are rendered in the status
  line.

Keep custom behavior near the existing numbered sections in
`.tmux.conf.local`. If a binding grows beyond a few lines, move the logic into
a script in this directory and keep the tmux binding as a thin entry point.

## Plugins

Configured plugins:

| Plugin | Purpose |
|:-------|:--------|
| `tmux-plugins/tmux-copycat` | Search/copy helpers, including `Prefix+/`. |
| `tmux-plugins/tmux-cpu` | CPU and memory status helpers. |
| `MunifTanjim/tmux-mode-indicator` | Status-line mode indicator. |
| `tmux-plugins/tmux-resurrect` | Manual session save/restore. |
| `tmux-plugins/tmux-continuum` | Automatic session save/restore. |
| `laktak/extrakto` | FZF-powered extraction/copy workflow on `Prefix+f`. |

Plugin auto-update and auto-uninstall are disabled in the local config to avoid
network-sensitive reloads changing the installed plugin set. Use the normal TPM
commands manually when plugin maintenance is intended.

## Key Bindings

| Key | Script | Purpose |
|:----|:-------|:--------|
| `Cmd+p` / `M-p` | `popup_terminal.sh` | Toggle the persistent project popup terminal. |
| `M-q` | `ai_pane_switch_popup.sh` | Find and jump to running AI CLI panes. |
| `M-w` | `pane_switch_popup.sh` | Find and jump to any tmux pane. |
| `Cmd+o` | `smart-open.sh` | Open the clipboard path, or the current pane directory. |
| status line | `net_speed.sh` | Render compact network throughput. |

`Cmd+p` is mapped by Ghostty to the same escape sequence as `M-p`.

## Maintenance Rules

- Put quick references in `cheatsheet.txt`.
- Put workflow and script behavior here.
- Keep script headers short: trigger, behavior, and safety notes only.
- Prefer scripts over long escaped `run-shell` blocks in `.tmux.conf.local`.
- Avoid hidden `send-keys` flows unless the target pane state is checked first.

## Scripts

### `popup_terminal.sh`

Persistent popup terminal for quick project-directory access.

- Called by `Cmd+p` / `M-p`.
- Uses a single `_popup` tmux session.
- Creates or reuses one `_popup` window per source pane directory.
- Reuses an existing directory window instead of blindly typing `cd`.
- Defaults to `TMUX_POPUP_MAX_WINDOWS=5`.
- When the soft window cap is reached, only non-active shell windows are closed.
- If all existing windows are busy or non-shell commands, the cap is exceeded instead of killing work.
- After routing to a shell window, sends `Ctrl+L` and runs `git status`.
- Does not send keys to non-shell windows such as `nvim`, `claude`, `codex`, `top`, or `ssh`.

### `ai_pane_switch_popup.sh`

AI pane switcher.

- Called by `M-q`.
- Finds panes whose process tree contains AI CLIs such as `claude`, `codex`, `gemini`, `amp`, `agent`, or `droid`.
- Shows the result in a tmux popup with fzf.
- Uses `ai_pane_summary.sh` for preview summaries.
- `M-r` refreshes summaries inside the popup.
- `M-t` toggles the preview pane.

### `ai_pane_summary.sh`

AI pane preview helper.

- Captures target pane content.
- Produces cached summaries for `ai_pane_switch_popup.sh`.
- Supports raw preview mode when a model summary is not needed.
- Uses a cache under `${TMPDIR:-/tmp}/ai_pane_summary_cache`.

### `pane_switch_popup.sh`

Global pane switcher.

- Called by `M-w`.
- Lists all tmux panes with fzf.
- Shows a live capture preview for the selected pane.
- Switches to the selected pane, detaching from `_popup` first if needed.

### `smart-open.sh`

Smart macOS opener for tmux.

- Called by `Cmd+o` through tmux `user-keys[0]`.
- If the clipboard contains an existing path, opens that path.
- Otherwise opens the current pane directory.
- Supports `file://` prefixes and `~` expansion.

### `net_speed.sh`

Status-line network speed renderer.

- Reads macOS network counters.
- Stores the previous sample in `/tmp/.tmux_net_speed_<iface>`.
- Prints a fixed-width status segment to avoid status-line jitter.

## Config

Main config file:

- `tmux/.tmux.conf.local`

Quick reference:

- `tmux/cheatsheet.txt`
