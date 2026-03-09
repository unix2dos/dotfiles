#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')

if [ -z "$cwd" ]; then
  cwd=$(pwd)
fi

cd "$cwd" 2>/dev/null || exit 0

# Shorten path: replace $HOME with ~
short_path="${cwd/#$HOME/~}"

# Git info
git_info=""
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git_info=" $branch *"
  else
    git_info=" $branch"
  fi
fi

printf '%s%s' "$short_path" "$git_info"
