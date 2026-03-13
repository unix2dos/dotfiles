#!/bin/bash
# ============================================
# Skills 来源声明
# ============================================
# 定义三类来源目录及优先级，同名 skill 取第一个命中项：
#   owned > generated > third-party
# ============================================

set -euo pipefail

# 自有 skills 源码目录
DEFAULT_OWNED_SKILLS_ROOT="$HOME/workspace/skills"
# 生成/适配层目录（如 ed3d 兼容转换产物）
DEFAULT_GENERATED_SKILLS_ROOT="$HOME/workspace/compat-ed3d/targets/codex/skills"

# 返回自有 skills 根目录（支持环境变量覆盖）
owned_skills_root() {
  printf '%s\n' "${OWNED_SKILLS_ROOT:-$DEFAULT_OWNED_SKILLS_ROOT}"
}

# 返回生成层 skills 根目录
generated_skills_root() {
  printf '%s\n' "${GENERATED_SKILLS_ROOT:-$DEFAULT_GENERATED_SKILLS_ROOT}"
}

# 返回第三方 skills 根目录
third_party_skills_root() {
  printf '%s\n' "${THIRD_PARTY_SKILLS_ROOT:-$HOME/.codex/superpowers/skills}"
}

# 按优先级顺序列出所有可用来源
# 输出格式：label\tpath（每行一条）
# 目录不存在时输出警告到 stderr
list_skill_sources() {
  local label
  local path

  for label in owned generated third-party; do
    case "$label" in
      owned)
        path="$(owned_skills_root)"
        ;;
      generated)
        path="$(generated_skills_root)"
        ;;
      third-party)
        path="$(third_party_skills_root)"
        ;;
    esac

    if [ -d "$path" ]; then
      printf '%s\t%s\n' "$label" "$path"
    else
      printf 'WARN: missing %s skills root: %s\n' "$label" "$path" >&2
    fi
  done
}
