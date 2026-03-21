#!/bin/bash
# ============================================
# Skills 运行时安装脚本
# ============================================
# 从多个来源聚合 skills 到统一安装目录，
# 并将各 AI 工具的消费入口重定向到该目录。
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/sources.sh"

# --- 配置 ---
SKILLS_INSTALL_ROOT="${SKILLS_INSTALL_ROOT:-$HOME/.skills-installed}"
BACKUP_SUFFIX="${BACKUP_SUFFIX:-.backup}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d%H%M%S)}"

# 所有 AI 工具运行时的 skills 消费入口
# 安装后统一指向 $SKILLS_INSTALL_ROOT
CONSUMER_SKILL_LINKS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.config/alma/skills"
  "$HOME/.gemini/antigravity/skills"
  "$HOME/.openclaw/skills"
)

# --- 工具函数 ---

# 备份已有路径，并维护一个稳定的 .backup 软链接指向最近一次备份
backup_path() {
  local path="$1"

  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return
  fi

  local backup="${path}${BACKUP_SUFFIX}.${TIMESTAMP}"
  mv "$path" "$backup"
  rm -rf "${path}${BACKUP_SUFFIX}"
  ln -s "$backup" "${path}${BACKUP_SUFFIX}"
}

# 确保目标路径的父目录存在
ensure_parent_dir() {
  mkdir -p "$(dirname "$1")"
}

# 创建符号链接（已存在且正确则跳过）
link_entry() {
  local target="$1"
  local link_path="$2"

  ensure_parent_dir "$link_path"

  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    return
  fi

  rm -rf "$link_path"
  ln -s "$target" "$link_path"
}

# 将消费入口重定向到目标目录（先备份再链接）
repoint_consumer_link() {
  local target="$1"
  local link_path="$2"

  ensure_parent_dir "$link_path"

  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    return
  fi

  backup_path "$link_path"
  link_entry "$target" "$link_path"
}

# 扫描目录下所有包含 SKILL.md 的子目录（即有效 skill）
discover_skill_dirs() {
  local root="$1"

  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | sort
}

# --- 核心逻辑 ---

# 从零重建安装目录，按优先级聚合所有来源的 skills
# 同名 skill 保留高优先级版本，跳过低优先级
rebuild_install_root() {
  echo -e "\n\033[0;36m━━━ 正在重建 Skills 聚合层 ━━━\033[0m"
  rm -rf "$SKILLS_INSTALL_ROOT"
  mkdir -p "$SKILLS_INSTALL_ROOT"

  local total_skills=0

  while IFS=$'\t' read -r label root; do
    [ -n "$root" ] || continue

    local source_count=0
    while IFS= read -r skill_dir; do
      [ -n "$skill_dir" ] || continue
      local skill_name
      skill_name="$(basename "$skill_dir")"
      local link_path="$SKILLS_INSTALL_ROOT/$skill_name"

      if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        printf '\033[1;33m[WARN]\033[0m keeping higher-priority skill %s, skipping %s from %s\n' "$skill_name" "$skill_name" "$label" >&2
        continue
      fi

      ln -s "$skill_dir" "$link_path"
      ((source_count++))
      ((total_skills++))
    done < <(discover_skill_dirs "$root")
    
    if [ "$source_count" -gt 0 ]; then
      echo -e "\033[0;34m[INFO]\033[0m 来源 [${label}]: 添加了 ${source_count} 个 skill"
    fi
  done < <(list_skill_sources)
  
  echo -e "\033[0;32m[OK]\033[0m   共聚合 ${total_skills} 个独立 skill 到 ${SKILLS_INSTALL_ROOT}\n"
}

main() {
  rebuild_install_root

  echo -e "\033[0;36m━━━ 正在分发消费入口 ━━━\033[0m"
  # 将所有消费入口指向统一安装目录
  local consumer_link
  local linked_count=0
  for consumer_link in "${CONSUMER_SKILL_LINKS[@]}"; do
    repoint_consumer_link "$SKILLS_INSTALL_ROOT" "$consumer_link"
    echo -e "\033[0;34m[INFO]\033[0m 链接: ${consumer_link} -> ${SKILLS_INSTALL_ROOT}"
    ((linked_count++))
  done
  
  echo -e "\033[0;32m[OK]\033[0m   成功为 ${linked_count} 个 AI 工具分发了消费入口\n"
}

main "$@"
