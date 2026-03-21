#!/bin/bash
# ============================================
# Skills 来源声明
# ============================================
# 使用按顺序声明的来源列表，同名 skill 取第一个命中项。
# 当前启用：
#   1. owned       — 自有 skill 源码
#   2. superpowers  — obra/superpowers 工程流程框架
#   3. gstack      — garrytan/gstack 工程团队 skills
#   4. community   — 收藏的社区 skill（由 fetch.sh 拉取）
# ============================================

set -euo pipefail

# 自有 skills 源码目录
DEFAULT_OWNED_SKILLS_ROOT="$HOME/workspace/skills"
# gstack skills 目录（garrytan/gstack，Codex 格式，gstack-* 前缀）
DEFAULT_GSTACK_SKILLS_ROOT="$HOME/.skills-community/gstack/.agents/skills"
# 社区 skills 目录（收藏的三方 skill）
DEFAULT_COMMUNITY_SKILLS_ROOT="$HOME/.skills-community"
# superpowers skills 目录（obra/superpowers 工程流程框架）
DEFAULT_SUPERPOWERS_SKILLS_ROOT="$HOME/.skills-community/superpowers/skills"

# 按优先级顺序声明所有来源。
# 如需新增来源，请同时在两个数组尾部追加同索引项。
SKILL_SOURCE_LABELS=(
  "owned"
  "superpowers"
  "gstack"
  "community"
)

SKILL_SOURCE_PATHS=(
  "${OWNED_SKILLS_ROOT:-$DEFAULT_OWNED_SKILLS_ROOT}"
  "${SUPERPOWERS_SKILLS_ROOT:-$DEFAULT_SUPERPOWERS_SKILLS_ROOT}"
  "${GSTACK_SKILLS_ROOT:-$DEFAULT_GSTACK_SKILLS_ROOT}"
  "${COMMUNITY_SKILLS_ROOT:-$DEFAULT_COMMUNITY_SKILLS_ROOT}"
)

# 按优先级顺序列出所有可用来源
# 输出格式：label\tpath（每行一条）
# 目录不存在时输出警告到 stderr
list_skill_sources() {
  local i
  local label
  local path

  if [ "${#SKILL_SOURCE_LABELS[@]}" -ne "${#SKILL_SOURCE_PATHS[@]}" ]; then
    printf 'ERROR: skill source labels and paths length mismatch\n' >&2
    return 1
  fi

  for i in "${!SKILL_SOURCE_LABELS[@]}"; do
    label="${SKILL_SOURCE_LABELS[$i]}"
    path="${SKILL_SOURCE_PATHS[$i]}"

    if [ -d "$path" ]; then
      printf '%s\t%s\n' "$label" "$path"
    else
      printf 'WARN: missing %s skills root: %s\n' "$label" "$path" >&2
    fi
  done
}
