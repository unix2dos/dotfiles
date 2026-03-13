# Skills Install Layer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a platform-neutral runtime skill aggregation layer at `/Users/liuwei/.skills-installed`, move installation ownership into `dotfiles`, manage all current skill consumer entrypoints there, and return `/Users/liuwei/workspace/skills` to a pure source-repo role.

**Architecture:** Keep owned skills, third-party skills, and generated skills in separate source locations. Add a `dotfiles` installer that rebuilds a single runtime aggregation directory and repoints the live consumer entrypoints to it with backups.

**Tech Stack:** Bash, symlinks, macOS filesystem, git-managed dotfiles

---

### Task 1: Add an explicit skills source manifest

**Files:**
- Create: `/Users/liuwei/workspace/dotfiles/agents/skills/sources.sh`
- Create: `/Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh`

**Step 1: Write the failing test**

Add a shell test that creates temporary source directories for:

- `/Users/liuwei/workspace/skills`
- `/Users/liuwei/.codex/superpowers/skills`
- `/Users/liuwei/workspace/compat-ed3d/targets/codex/skills`

The test should source `sources.sh` and assert:

- all required source roots are declared
- disabled or missing roots are surfaced clearly
- source ordering is deterministic

**Step 2: Run test to verify it fails**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: FAIL because `sources.sh` does not exist yet.

**Step 3: Write minimal implementation**

Create `sources.sh` with:

- a function returning enabled source roots in priority order
- clear labels for owned, generated, and third-party sources
- environment overrides for testability

**Step 4: Run test to verify it passes**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: PASS and prints the ordered sources.

**Step 5: Commit**

```bash
git -C /Users/liuwei/workspace/dotfiles add agents/skills/sources.sh agents/skills/test-install.sh
git -C /Users/liuwei/workspace/dotfiles commit -m "feat: add skills source manifest"
```

### Task 2: Implement the neutral installer and entrypoint repointing

**Files:**
- Create: `/Users/liuwei/workspace/dotfiles/agents/skills/install.sh`
- Modify: `/Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh`

**Step 1: Write the failing test**

Extend the shell test to build a temporary fake home directory and assert that running the installer:

- creates `~/.skills-installed`
- links one owned skill, one `superpowers` skill, and one `ed3d-*` skill into it
- backs up all existing consumer entrypaths
- repoints all supported entrypaths to `~/.skills-installed`

**Step 2: Run test to verify it fails**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: FAIL because `install.sh` does not exist yet.

**Step 3: Write minimal implementation**

Create `install.sh` with:

- strict mode: `set -euo pipefail`
- reusable backup-and-link helpers
- source enumeration via `sources.sh`
- deterministic linking into `~/.skills-installed`
- duplicate handling with explicit priority
- repointing for all supported consumer entrypaths:
  - `~/.agents/skills`
  - `~/.claude/skills`
  - `~/.codex/skills`
  - `~/.config/opencode/skills`
  - `~/.config/alma/skills`
  - `~/.gemini/antigravity/skills`
  - `~/.openclaw/skills`

**Step 4: Run test to verify it passes**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: PASS and shows correct symlink targets without cycles.

**Step 5: Commit**

```bash
git -C /Users/liuwei/workspace/dotfiles add agents/skills/install.sh agents/skills/test-install.sh
git -C /Users/liuwei/workspace/dotfiles commit -m "feat: add skills installer"
```

### Task 3: Document the runtime model and operator workflow

**Files:**
- Create: `/Users/liuwei/workspace/dotfiles/agents/skills/README.md`
- Modify: `/Users/liuwei/workspace/dotfiles/README.md`

**Step 1: Write the failing test**

Define a doc checklist in `test-install.sh` that verifies documentation mentions:

- `/Users/liuwei/.skills-installed`
- source locations
- installer command
- backup behavior
- how to add a new source

**Step 2: Run test to verify it fails**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: FAIL because the documentation does not mention the new architecture yet.

**Step 3: Write minimal implementation**

Add `agents/skills/README.md` describing:

- source layer vs install layer
- supported current entrypoints
- how to run the installer
- how to add a new source safely

Update root `README.md` to point to the Codex skill installer docs.

**Step 4: Run test to verify it passes**

Run:

```bash
bash /Users/liuwei/workspace/dotfiles/agents/skills/test-install.sh
```

Expected: PASS and doc references are found.

**Step 5: Commit**

```bash
git -C /Users/liuwei/workspace/dotfiles add agents/skills/README.md README.md
git -C /Users/liuwei/workspace/dotfiles commit -m "docs: add skills installer guide"
```

### Task 4: Remove installation-role leakage from the skills source repo

**Files:**
- Modify: `/Users/liuwei/workspace/skills/skills-link.sh`
- Modify: `/Users/liuwei/workspace/skills/.gitignore`
- Remove runtime-only links from: `/Users/liuwei/workspace/skills`

**Step 1: Write the failing test**

Add a manual verification checklist documenting the current anti-goal state:

- `workspace/skills` still contains `superpowers`
- `workspace/skills` still contains `ed3d-*`
- `skills-link.sh` still assumes `workspace/skills` is the install source

**Step 2: Run test to verify it fails**

Run:

```bash
test -L /Users/liuwei/workspace/skills/superpowers
```

Expected: PASS today, which indicates the repository is still polluted with install-only links and cleanup is still required.

**Step 3: Write minimal implementation**

Update the skills repo so that:

- `skills-link.sh` no longer advertises `workspace/skills` as the universal runtime target
- runtime-only third-party and generated symlinks are removed
- `.gitignore` matches the new source-only role

**Step 4: Run test to verify it passes**

Run:

```bash
test ! -e /Users/liuwei/workspace/skills/superpowers
test ! -e /Users/liuwei/workspace/skills/ed3d-codebase-investigator
```

Expected: PASS because install-only links are gone from the source repo.

**Step 5: Commit**

```bash
git -C /Users/liuwei/workspace/skills add skills-link.sh .gitignore
git -C /Users/liuwei/workspace/skills commit -m "refactor: separate skills source from install layer"
```

### Task 5: Cut over the live machine state and verify the accepted paths

**Files:**
- Use: `/Users/liuwei/workspace/dotfiles/agents/skills/install.sh`
- Verify: `/Users/liuwei/.skills-installed`
- Verify: `/Users/liuwei/.codex/skills`
- Verify: `/Users/liuwei/.agents/skills`
- Verify: `/Users/liuwei/.claude/skills`
- Verify: `/Users/liuwei/.config/opencode/skills`
- Verify: `/Users/liuwei/.config/alma/skills`
- Verify: `/Users/liuwei/.gemini/antigravity/skills`
- Verify: `/Users/liuwei/.openclaw/skills`

**Step 1: Write the failing test**

Prepare a verification checklist for:

- no circular symlinks
- one owned skill resolves to `workspace/skills`
- one `superpowers` skill resolves to `~/.codex/superpowers`
- one `ed3d-*` skill resolves to `workspace/compat-ed3d`

**Step 2: Run test to verify it fails**

Run:

```bash
readlink /Users/liuwei/.codex/skills
readlink /Users/liuwei/.agents/skills
readlink /Users/liuwei/.claude/skills
readlink /Users/liuwei/.config/opencode/skills
readlink /Users/liuwei/.config/alma/skills
readlink /Users/liuwei/.gemini/antigravity/skills
readlink /Users/liuwei/.openclaw/skills
```

Expected: outputs do not yet match `/Users/liuwei/.skills-installed`.

**Step 3: Write minimal implementation**

Run the installer on the real environment and keep timestamped backups for previous live paths.

**Step 4: Run test to verify it passes**

Run:

```bash
readlink /Users/liuwei/.codex/skills
readlink /Users/liuwei/.agents/skills
readlink /Users/liuwei/.skills-installed/ed3d-codebase-investigator
readlink /Users/liuwei/.skills-installed/brainstorming
```

Expected:

- all supported consumer entrypaths resolve to `/Users/liuwei/.skills-installed`
- `ed3d-codebase-investigator` resolves to `/Users/liuwei/workspace/compat-ed3d/...`
- `brainstorming` resolves to the chosen source according to priority

**Step 5: Commit**

```bash
git -C /Users/liuwei/workspace/dotfiles add agents/skills/install.sh agents/skills/sources.sh agents/skills/README.md README.md docs/plans/2026-03-13-skills-install-layer-design.md docs/plans/2026-03-13-skills-install-layer-implementation-plan.md
git -C /Users/liuwei/workspace/dotfiles commit -m "feat: add neutral skills install layer"
```
