#!/bin/bash
# ============================================
# Skills 一键安装
# ============================================
# 从零开始：克隆所有来源 → 拉取外部资源 → 聚合分发。
# 已存在的来源会自动跳过或更新。
#
# 用法:
#   bash install.sh            # 安装/更新全部
#   bash install.sh --dry-run  # 仅预览，不实际修改
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/sources.sh"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_header()  { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }

# ─── 克隆或更新一个 git 仓库 ─────────────────────────────────────

clone_or_pull() {
  local label="$1"
  local repo_url="$2"
  local dest="$3"
  local branch="${4:-main}"

  if [[ -d "$dest/.git" ]]; then
    log_info "$label 已存在，拉取更新..."
    if [[ "$DRY_RUN" == false ]]; then
      git -C "$dest" pull --ff-only --quiet 2>/dev/null || {
        log_warn "$label fast-forward 失败，尝试 fetch + reset..."
        git -C "$dest" fetch --depth 1 origin "$branch" --quiet
        git -C "$dest" reset --hard "origin/$branch" --quiet
      }
    fi
    log_success "$label 已更新"
  elif [[ -d "$dest" ]]; then
    log_warn "$label 目录已存在但不是 git 仓库: $dest（跳过）"
  else
    log_info "$label 不存在，正在克隆..."
    if [[ "$DRY_RUN" == false ]]; then
      git clone --depth 1 --branch "$branch" "$repo_url" "$dest" --quiet
    fi
    log_success "$label 已克隆到 $dest"
  fi
}

# ─── 主流程 ───────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    Skills 一键安装                          ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

  if [[ "$DRY_RUN" == true ]]; then
    log_warn "DRY-RUN 模式: 不会修改任何文件"
  fi

  # ── Step 1: 克隆/更新所有来源仓库 ──
  log_header "Step 1/3 — 克隆来源仓库"

  clone_or_pull "owned (unix2dos/skills)" \
    "https://github.com/unix2dos/skills.git" \
    "${OWNED_SKILLS_ROOT:-$DEFAULT_OWNED_SKILLS_ROOT}"

  clone_or_pull "superpowers (obra/superpowers)" \
    "https://github.com/obra/superpowers.git" \
    "$HOME/.skills-community/superpowers"

  clone_or_pull "gstack (garrytan/gstack)" \
    "https://github.com/garrytan/gstack.git" \
    "$HOME/.skills-community/gstack"

  # ── Step 2: 构建 + 拉取社区 skills ──
  log_header "Step 2/3 — 构建 + 拉取社区 skills"

  if [[ "$DRY_RUN" == true ]]; then
    bash "$SCRIPT_DIR/fetch.sh" --dry-run
  else
    bash "$SCRIPT_DIR/fetch.sh"
  fi

  # ── Step 3: 聚合 + 分发 ──
  log_header "Step 3/3 — 聚合分发"
  bash "$SCRIPT_DIR/link.sh"

  echo ""
  log_success "全部完成！"
}

main "$@"
