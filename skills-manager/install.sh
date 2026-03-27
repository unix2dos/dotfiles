#!/bin/bash
# ============================================
# Skills 一键安装
# ============================================
# 读取 sources.yaml，完成：克隆 → 构建 → 聚合 → 分发。
# 所有配置在 sources.yaml，本脚本只有逻辑。
#
# 用法:
#   bash install.sh            # 安装/更新全部
#   bash install.sh --dry-run  # 仅预览，不实际修改
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/skills_sources.yaml"
CLAUDE_CONFIG="$SCRIPT_DIR/skills_claude.yaml"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
DRY_RUN=false
TMPDIR_BASE=""

# skill_link_name -> source_name mapping (populated in step_link)
# Format: "|link_name=source_name|..." (bash 3.x compatible)
SKILL_SOURCE_MAP="|"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      echo "Usage: bash install.sh [--dry-run]"
      exit 0
      ;;
  esac
done

# ─── check ────────────────────────────────────────────────────────

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq not found. Run: brew install yq" >&2
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: config not found: ${CONFIG}" >&2
  exit 1
fi

# ─── colors & log ─────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*"; }
log_header()  { echo -e "\n${CYAN}--- $* ---${NC}"; }

# ─── utils ────────────────────────────────────────────────────────

expand_path() { echo "${1/#\~/$HOME}"; }

cfg() {
  local val
  val="$(yq -r "$1" "$CONFIG")"
  [[ "$val" == "null" ]] && echo "" && return
  expand_path "$val"
}

cfg_raw() {
  local val
  val="$(yq -r "$1" "$CONFIG")"
  [[ "$val" == "null" ]] && echo "" && return
  echo "$val"
}

is_skill_excluded() {
  local idx="$1" skill_name="$2"
  local exclude_count
  exclude_count=$(yq ".sources[$idx].exclude | length" "$CONFIG" 2>/dev/null)
  [[ "$exclude_count" == "0" || "$exclude_count" == "null" ]] && return 1
  for ((k = 0; k < exclude_count; k++)); do
    local excluded
    excluded=$(cfg_raw ".sources[$idx].exclude[$k]")
    [[ "$excluded" == "$skill_name" ]] && return 0
  done
  return 1
}

get_skill_link_name() {
  local idx="$1" skill_name="$2"
  local prefix
  prefix=$(cfg_raw ".sources[$idx].prefix")
  if [[ -n "$prefix" ]]; then
    echo "${prefix}-${skill_name}"
  else
    echo "$skill_name"
  fi
}

clone_or_pull() {
  local label="$1" repo_url="$2" dest="$3" branch="${4:-main}"

  if [[ -d "$dest/.git" ]]; then
    log_info "${label}: pulling..."
    if [[ "$DRY_RUN" == false ]]; then
      git -C "$dest" pull --ff-only --quiet 2>/dev/null || {
        log_warn "${label}: ff failed, fetch + reset..."
        git -C "$dest" fetch --depth 1 origin "$branch" --quiet
        git -C "$dest" reset --hard "origin/$branch" --quiet
      }
    fi
    log_success "${label}: updated"
  elif [[ -d "$dest" ]]; then
    log_warn "${label}: exists but not a git repo: ${dest} (skip)"
  else
    log_info "${label}: cloning..."
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$(dirname "$dest")"
      git clone --depth 1 --branch "$branch" "$repo_url" "$dest" --quiet
    fi
    log_success "${label}: cloned to ${dest}"
  fi
}

discover_skill_dirs() {
  local root="$1"
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | sort
}

cleanup() {
  if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
    rm -rf "$TMPDIR_BASE"
  fi
}

# ─── Step 0: clean ────────────────────────────────────────────────

step_clean() {
  log_header "Step 0/5 — clean stale dirs"

  local community_dir install_dir
  community_dir=$(cfg '.community_dir')
  install_dir=$(cfg '.install_dir')

  for dir in "$community_dir" "$install_dir"; do
    if [[ -z "$dir" ]]; then continue; fi
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] would remove: ${dir}"
    elif [[ -e "$dir" || -L "$dir" ]]; then
      rm -rf "$dir"
      log_success "removed: ${dir}"
    fi
  done
}

# ─── Step 1: clone ────────────────────────────────────────────────

step_clone() {
  log_header "Step 1/5 — clone repos"

  local count
  count=$(yq '.sources | length' "$CONFIG")

  for ((i = 0; i < count; i++)); do
    local name repo clone_to branch
    name=$(cfg_raw ".sources[$i].name")

    repo=$(cfg_raw ".sources[$i].repo")
    clone_to=$(cfg ".sources[$i].clone_to")
    branch=$(cfg_raw ".sources[$i].branch")
    branch="${branch:-main}"

    [[ -z "$repo" ]] && continue

    clone_or_pull "$name" "$repo" "$clone_to" "$branch"
  done
}

# ─── Step 2: build + fetch community ─────────────────────────────

step_build_and_fetch() {
  log_header "Step 2/5 — build + fetch community"

  local count
  count=$(yq '.sources | length' "$CONFIG")

  for ((i = 0; i < count; i++)); do
    local name clone_to build
    name=$(cfg_raw ".sources[$i].name")

    clone_to=$(cfg ".sources[$i].clone_to")
    build=$(cfg_raw ".sources[$i].build")

    # ── build ──
    if [[ -n "$build" ]]; then
      log_info "${name}: building..."
      if [[ "$DRY_RUN" == false ]]; then
        (cd "$clone_to" && eval "$build") || {
          log_error "${name}: build failed"
          continue
        }

        # runtime asset symlinks
        local assets_count
        assets_count=$(yq ".sources[$i].runtime_assets | length" "$CONFIG")
        if [[ "$assets_count" -gt 0 ]]; then
          local skills_dir
          skills_dir=$(cfg_raw ".sources[$i].skills_dir")
          local main_skill_dir="${clone_to}/${skills_dir}/${name}"
          for ((j = 0; j < assets_count; j++)); do
            local asset
            asset=$(cfg_raw ".sources[$i].runtime_assets[$j]")
            local src="${clone_to}/${asset}"
            local dst="${main_skill_dir}/${asset}"
            if [[ -d "$src" ]] && { [[ -L "$dst" ]] || [[ ! -e "$dst" ]]; }; then
              ln -snf "$src" "$dst"
            fi
          done
        fi
      else
        log_info "[DRY-RUN] skip build: ${build}"
      fi
      log_success "${name}: build done"
    fi

    # ── fetch community skills (clone + rsync) ──
    local skills_count
    skills_count=$(yq ".sources[$i].skills | length" "$CONFIG" 2>/dev/null)
    [[ "$skills_count" == "0" || "$skills_count" == "null" ]] && continue

    log_info "${name}: fetching ${skills_count} skills..."

    TMPDIR_BASE="$(mktemp -d)"
    trap cleanup EXIT

    local success=0 failed=0

    for ((j = 0; j < skills_count; j++)); do
      local skill_name skill_repo skill_subdir skill_branch
      skill_name=$(cfg_raw ".sources[$i].skills[$j].name")

      # skip excluded community skill
      if is_skill_excluded "$i" "$skill_name"; then
        log_info "  exclude: ${skill_name}"
        continue
      fi

      skill_repo=$(cfg_raw ".sources[$i].skills[$j].repo")
      skill_subdir=$(cfg_raw ".sources[$i].skills[$j].subdir")
      skill_branch=$(cfg_raw ".sources[$i].skills[$j].branch")
      skill_branch="${skill_branch:-main}"
      skill_subdir="${skill_subdir:-.}"

      local local_dir="${clone_to}/${skill_name}"
      local clone_dir="${TMPDIR_BASE}/${skill_name}"
      local repo_url="https://github.com/${skill_repo}.git"

      log_info "  ${skill_name} <- ${skill_repo}"

      if ! git clone --depth 1 --branch "$skill_branch" --quiet "$repo_url" "$clone_dir" 2>/dev/null; then
        log_error "  ${skill_name}: clone failed"
        ((failed++))
        continue
      fi

      local src_dir
      if [[ "$skill_subdir" == "." ]]; then
        src_dir="$clone_dir"
      else
        src_dir="${clone_dir}/${skill_subdir}"
      fi

      if [[ ! -d "$src_dir" ]]; then
        log_error "  ${skill_name}: subdir not found: ${skill_subdir}"
        ((failed++))
        continue
      fi

      local rsync_excludes=("--exclude=.git")
      if [[ "$skill_subdir" == "." ]]; then
        for excl in README.md README_CN.md LICENSE .gitignore .github; do
          rsync_excludes+=("--exclude=$excl")
        done
      fi

      if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$local_dir"
        rsync -av --delete "${rsync_excludes[@]}" "$src_dir/" "$local_dir/" >/dev/null 2>&1
        # patch: ensure SKILL.md name matches the configured skill_name
        local skill_md="${local_dir}/SKILL.md"
        if [[ -f "$skill_md" ]]; then
          sed -i '' "s/^name: .*/name: ${skill_name}/" "$skill_md"
        fi
      fi
      ((success++))
    done

    cleanup
    TMPDIR_BASE=""
    log_success "${name}: ${success} ok, ${failed} failed"

    # ── prune stale community skill dirs ──
    # collect configured skill names into a lookup string "|name1|name2|...|"
    local configured="|"
    for ((j = 0; j < skills_count; j++)); do
      configured+="|$(cfg_raw ".sources[$i].skills[$j].name")|"
    done
    # remove any dir with SKILL.md whose name is not in the configured list
    # skip git repos (dirs managed by other sources, e.g. gstack, superpowers)
    local pruned=0
    while IFS= read -r stale_dir; do
      local sname
      sname="$(basename "$stale_dir")"
      if [[ -d "${stale_dir}/.git" ]]; then
        continue
      fi
      if [[ "$configured" != *"|${sname}|"* ]]; then
        log_warn "pruning stale skill: ${sname}"
        if [[ "$DRY_RUN" == false ]]; then
          rm -rf "$stale_dir"
        fi
        ((pruned++))
      fi
    done < <(discover_skill_dirs "$clone_to")
    if [[ "$pruned" -gt 0 ]]; then
      log_info "${name}: pruned ${pruned} stale skill(s)"
    fi
  done
}

# ─── Step 3: aggregate + link ─────────────────────────────────────

step_link() {
  log_header "Step 3/5 — aggregate + link"

  local install_dir
  install_dir=$(cfg '.install_dir')

  # ── aggregate ──
  mkdir -p "$install_dir"

  local total_skills=0
  local source_count
  source_count=$(yq '.sources | length' "$CONFIG")
  # Track claimed skill names for priority (first source wins)
  local claimed_skills="|"

  for ((i = 0; i < source_count; i++)); do
    local name clone_to skills_dir
    name=$(cfg_raw ".sources[$i].name")

    clone_to=$(cfg ".sources[$i].clone_to")
    skills_dir=$(cfg_raw ".sources[$i].skills_dir")

    local scan_root
    if [[ -n "$skills_dir" && "$skills_dir" != "." ]]; then
      scan_root="${clone_to}/${skills_dir}"
    else
      scan_root="$clone_to"
    fi

    [[ ! -d "$scan_root" ]] && continue

    local count=0
    while IFS= read -r skill_dir; do
      [[ -n "$skill_dir" ]] || continue
      local sname
      sname="$(basename "$skill_dir")"

      # exclude check
      if is_skill_excluded "$i" "$sname"; then
        log_info "exclude ${sname} from ${name}"
        continue
      fi

      # prefix
      local link_name
      link_name=$(get_skill_link_name "$i" "$sname")

      # priority: first source to claim a name wins
      if [[ "$claimed_skills" == *"|${link_name}|"* ]]; then
        log_warn "keep higher-priority ${link_name}, skip from ${name}"
        continue
      fi

      claimed_skills="${claimed_skills}${link_name}|"
      SKILL_SOURCE_MAP="${SKILL_SOURCE_MAP}${link_name}=${name}|"

      local link_path="${install_dir}/${link_name}"
      if [[ "$DRY_RUN" == false ]]; then
        ln -s "$skill_dir" "$link_path"
      fi
      ((count++))
      ((total_skills++))
    done < <(discover_skill_dirs "$scan_root")

    if [[ "$count" -gt 0 ]]; then
      log_info "source [${name}]: ${count} skills"
    fi
  done

  log_success "total: ${total_skills} skills -> ${install_dir}"

  # ── link consumers ──
  local consumer_count
  consumer_count=$(yq '.consumers | length' "$CONFIG")
  local linked=0

  for ((i = 0; i < consumer_count; i++)); do
    local consumer
    consumer=$(cfg ".consumers[$i]")

    # skip claude — handled separately in step_claude
    if [[ "$consumer" == "$CLAUDE_SKILLS_DIR" ]]; then
      continue
    fi

    mkdir -p "$(dirname "$consumer")"

    if [[ -L "$consumer" && "$(readlink "$consumer")" == "$install_dir" ]]; then
      ((linked++))
      continue
    fi

    if [[ -e "$consumer" || -L "$consumer" ]]; then
      mv "$consumer" "${consumer}.backup.$(date +%Y%m%d%H%M%S)"
    fi

    ln -s "$install_dir" "$consumer"
    log_info "link: ${consumer} -> ${install_dir}"
    ((linked++))
  done

  log_success "linked to ${linked} AI tools (Claude Code handled separately)"
}

# ─── Step 4: Claude Code filtered install ────────────────────────

step_claude() {
  log_header "Step 4/5 — Claude Code filtered install"

  local install_dir
  install_dir=$(cfg '.install_dir')

  # ── load whitelist from sources_claude.yaml ──
  # Store as "|name1|name2|..." for bash 3.x compatible lookup
  local claude_include_sources="|"
  local claude_include_skills="|"
  local has_config=false

  if [[ -f "$CLAUDE_CONFIG" ]]; then
    has_config=true
    log_info "loading sources_claude.yaml (whitelist mode)"

    local is_count
    is_count=$(yq '.include_sources | length' "$CLAUDE_CONFIG" 2>/dev/null)
    if [[ "$is_count" != "0" && "$is_count" != "null" ]]; then
      for ((i = 0; i < is_count; i++)); do
        local src
        src=$(yq -r ".include_sources[$i]" "$CLAUDE_CONFIG")
        claude_include_sources="${claude_include_sources}${src}|"
      done
    fi

    local ik_count
    ik_count=$(yq '.include | length' "$CLAUDE_CONFIG" 2>/dev/null)
    if [[ "$ik_count" != "0" && "$ik_count" != "null" ]]; then
      for ((i = 0; i < ik_count; i++)); do
        local sk
        sk=$(yq -r ".include[$i]" "$CLAUDE_CONFIG")
        claude_include_skills="${claude_include_skills}${sk}|"
      done
    fi

    log_info "include_sources: ${claude_include_sources}"
    log_info "include_skills:  ${claude_include_skills}"
  else
    log_info "sources_claude.yaml not found, installing all skills"
  fi

  # ── prepare ~/.claude/skills as physical directory ──
  if [[ "$DRY_RUN" == false ]]; then
    if [[ -L "$CLAUDE_SKILLS_DIR" ]]; then
      rm -f "$CLAUDE_SKILLS_DIR"
    elif [[ -d "$CLAUDE_SKILLS_DIR" ]]; then
      rm -rf "$CLAUDE_SKILLS_DIR"
    fi
    mkdir -p "$CLAUDE_SKILLS_DIR"
  fi

  # ── create filtered symlinks ──
  local included=0 skipped=0

  for link_path in "$install_dir"/*; do
    [[ -e "$link_path" || -L "$link_path" ]] || continue

    local link_name
    link_name="$(basename "$link_path")"

    # if no config, install everything
    if [[ "$has_config" == true ]]; then
      # lookup source name from SKILL_SOURCE_MAP
      local source_name="unknown"
      if [[ "$SKILL_SOURCE_MAP" == *"|${link_name}="* ]]; then
        source_name="${SKILL_SOURCE_MAP#*|${link_name}=}"
        source_name="${source_name%%|*}"
      fi

      # whitelist: must match include_sources OR include
      local allowed=false
      if [[ "$claude_include_sources" == *"|${source_name}|"* ]]; then
        allowed=true
      elif [[ "$claude_include_skills" == *"|${link_name}|"* ]]; then
        allowed=true
      fi

      if [[ "$allowed" == false ]]; then
        log_info "  skip (not in whitelist): ${link_name}"
        ((skipped++))
        continue
      fi
    fi

    # create symlink: ~/.claude/skills/xxx -> actual skill dir
    local target
    if [[ "$DRY_RUN" == true ]]; then
      # in dry-run, resolve from SKILL_SOURCE_MAP context
      ((included++))
    else
      target="$(readlink "$link_path")"
      ln -s "$target" "${CLAUDE_SKILLS_DIR}/${link_name}"
      ((included++))
    fi
  done

  log_success "Claude Code: ${included} skills installed, ${skipped} skipped"
}

# ─── main ─────────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    Skills Installer                        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

  if [[ "$DRY_RUN" == true ]]; then
    log_warn "DRY-RUN mode"
  fi

  step_clean
  step_clone
  step_build_and_fetch
  step_link
  step_claude

  echo ""
  log_success "all done!"
}

main "$@"
