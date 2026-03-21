#!/bin/bash
# ============================================
# 外部 Skills 构建 + 拉取
# ============================================
# gstack 构建（bun build）+ 社区 skills 拉取。
# 用法:
#   bash fetch.sh            # 执行更新
#   bash fetch.sh --dry-run  # 仅预览，不实际修改
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/sources.sh"

COMMUNITY_DIR="${COMMUNITY_SKILLS_ROOT:-$DEFAULT_COMMUNITY_SKILLS_ROOT}"
GSTACK_DIR="${GSTACK_SKILLS_ROOT:-$HOME/.skills-community/gstack}"
DRY_RUN=false
TMPDIR_BASE=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── 社区 Skill 映射表 ───────────────────────────────────────────
# 格式: "本地目录名|GitHub仓库|上游子目录(. 表示仓库根目录)|默认分支"
SKILLS=(
  "my-code-review|supercent-io/skills-template|.agent-skills/code-review|main"
  "skill-creator|anthropics/skills|skills/skill-creator|main"
  "yt-dlp-downloader|MapleShaw/yt-dlp-downloader-skill|.|master"
  "humanizer-zh|op7418/Humanizer-zh|.|main"
  "find-skills|vercel-labs/skills|skills/find-skills|main"
  "hackernews|vm0-ai/vm0-skills|hackernews|main"
  "architecture-designer|Jeffallan/claude-skills|skills/architecture-designer|main"
  "asking-clarifying-questions|ed3dai/ed3d-plugins|plugins/ed3d-plan-and-execute/skills/asking-clarifying-questions|main"
)

# 仓库根目录同步时需要排除的文件
REPO_ROOT_EXCLUDES=(
  "README.md"
  "README_CN.md"
  "LICENSE"
  ".git"
  ".gitignore"
  ".github"
)

# ─── 函数 ────────────────────────────────────────────────────────

cleanup() {
  if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
    rm -rf "$TMPDIR_BASE"
  fi
}

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*"; }
log_header()  { echo -e "\n${CYAN}━━━ $* ━━━${NC}"; }

update_skill() {
  local local_name="$1"
  local repo="$2"
  local upstream_path="$3"
  local branch="$4"

  local local_dir="$COMMUNITY_DIR/$local_name"
  local clone_dir="$TMPDIR_BASE/$local_name"
  local repo_url="https://github.com/${repo}.git"

  log_header "$local_name"
  log_info "上游: ${repo} (branch: ${branch}, path: ${upstream_path})"

  # 1. 浅克隆上游仓库
  log_info "正在拉取上游仓库..."
  if ! git clone --depth 1 --branch "$branch" --quiet "$repo_url" "$clone_dir" 2>/dev/null; then
    log_error "克隆失败: $repo_url"
    return 1
  fi

  # 2. 确定源目录
  local src_dir
  if [[ "$upstream_path" == "." ]]; then
    src_dir="$clone_dir"
  else
    src_dir="$clone_dir/$upstream_path"
  fi

  if [[ ! -d "$src_dir" ]]; then
    log_error "上游路径不存在: $upstream_path"
    return 1
  fi

  # 3. 构建 rsync 排除参数
  local rsync_excludes=("--exclude=.git")
  if [[ "$upstream_path" == "." ]]; then
    for excl in "${REPO_ROOT_EXCLUDES[@]}"; do
      rsync_excludes+=("--exclude=$excl")
    done
  fi

  # 4. 同步文件
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] 将要同步的文件:"
    rsync -avn --delete "${rsync_excludes[@]}" "$src_dir/" "$local_dir/" 2>/dev/null | head -30
  else
    mkdir -p "$local_dir"
    rsync -av --delete "${rsync_excludes[@]}" "$src_dir/" "$local_dir/" >/dev/null 2>&1
    log_success "$local_name 更新完成"
  fi

  return 0
}

# ─── gstack 更新 ──────────────────────────────────────────────────

# gstack 运行时资源目录（skills 通过 ~/.codex/skills/gstack/bin/... 引用）
GSTACK_RUNTIME_ASSETS=(bin browse review qa)

update_gstack() {
  log_header "gstack 构建"

  if [[ ! -d "$GSTACK_DIR/.git" ]]; then
    log_warn "gstack 仓库不存在，请先运行 install.sh"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] 跳过构建步骤"
    return 0
  fi

  # 2. 安装依赖并构建
  log_info "正在安装依赖并构建..."
  (
    cd "$GSTACK_DIR"
    bun install --silent 2>/dev/null
    bun run build 2>/dev/null
  ) || {
    log_error "gstack 构建失败"
    return 1
  }

  # 3. 在 .agents/skills/gstack/ 中创建运行时资源符号链接
  #    确保 ~/.codex/skills/gstack/bin/... 等路径可达
  local gstack_skill_dir="$GSTACK_DIR/.agents/skills/gstack"
  for asset in "${GSTACK_RUNTIME_ASSETS[@]}"; do
    local src="$GSTACK_DIR/$asset"
    local dst="$gstack_skill_dir/$asset"
    if [[ -d "$src" ]] && { [[ -L "$dst" ]] || [[ ! -e "$dst" ]]; }; then
      ln -snf "$src" "$dst"
    fi
  done

  log_success "gstack 更新完成（含运行时资源链接）"
  return 0
}

# ─── 主流程 ───────────────────────────────────────────────────────

main() {
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=true ;;
      -h|--help)
        echo "用法: bash fetch.sh [--dry-run]"
        echo ""
        echo "  --dry-run  仅预览变更，不实际修改文件"
        echo "  -h,--help  显示帮助信息"
        exit 0
        ;;
      *)
        echo "未知参数: $arg"
        exit 1
        ;;
    esac
  done

  TMPDIR_BASE="$(mktemp -d)"
  trap cleanup EXIT

  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    社区 Skill 批量更新工具                 ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    log_warn "DRY-RUN 模式: 不会修改任何文件"
  fi

  # ── gstack 单独更新（独立仓库，非 SKILLS 映射表） ──
  log_info "gstack 目录: $GSTACK_DIR"
  local gstack_ok=0
  if update_gstack; then
    gstack_ok=1
  fi

  log_info "目标目录: $COMMUNITY_DIR"
  log_info "待更新 Skill 数量: ${#SKILLS[@]}"

  local success=0
  local failed=0
  local failed_names=()

  for entry in "${SKILLS[@]}"; do
    IFS='|' read -r local_name repo upstream_path branch <<< "$entry"

    if update_skill "$local_name" "$repo" "$upstream_path" "$branch"; then
      ((success++))
    else
      ((failed++))
      failed_names+=("$local_name")
    fi
  done

  # 输出报告
  echo ""
  log_header "更新报告"
  log_info "gstack: $([ $gstack_ok -eq 1 ] && echo -e "${GREEN}成功${NC}" || echo -e "${RED}失败${NC}")"
  log_info "社区 skills 总计: ${#SKILLS[@]}  成功: ${GREEN}${success}${NC}  失败: ${RED}${failed}${NC}"

  if [[ ${#failed_names[@]} -gt 0 ]]; then
    log_error "失败的 Skill: ${failed_names[*]}"
  fi

  if [[ "$DRY_RUN" == false && $success -gt 0 ]]; then
    echo ""
    log_info "提示: 社区 skills 已更新到 ${YELLOW}${COMMUNITY_DIR}${NC}"
    log_info "运行 ${YELLOW}bash $SCRIPT_DIR/link.sh${NC} 重建安装层"
  fi

  [[ $failed -eq 0 ]]
}

main "$@"
