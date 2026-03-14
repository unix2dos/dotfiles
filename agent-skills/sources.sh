#!/bin/bash
# ============================================
# Skills 来源声明
# ============================================
# 使用按顺序声明的来源列表，同名 skill 取第一个命中项。
# 当前启用：
#   1. owned
#   2. third-party
# ============================================

set -euo pipefail

# 自有 skills 源码目录
DEFAULT_OWNED_SKILLS_ROOT="$HOME/workspace/skills"
# 第三方 skills 根目录
DEFAULT_THIRD_PARTY_SKILLS_ROOT="$HOME/.codex/superpowers/skills"

# 按优先级顺序声明所有来源。
# 如需新增来源，请同时在两个数组尾部追加同索引项。
SKILL_SOURCE_LABELS=(
  "owned"
  "third-party"
)

SKILL_SOURCE_PATHS=(
  "${OWNED_SKILLS_ROOT:-$DEFAULT_OWNED_SKILLS_ROOT}"
  "${THIRD_PARTY_SKILLS_ROOT:-$DEFAULT_THIRD_PARTY_SKILLS_ROOT}"
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
