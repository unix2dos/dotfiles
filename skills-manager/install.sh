#!/bin/bash
# ============================================
# Skills 一键安装
# ============================================
# 读取 skills_sources.yaml + skills_consumers.yaml，完成：
#   clone → build → aggregate → 按 consumer 配置分发
#
# 用法:
#   bash install.sh            # 安装/更新全部
#   bash install.sh --dry-run  # 仅预览，不实际修改
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_CONFIG="$SCRIPT_DIR/skills_sources.yaml"
CONSUMERS_CONFIG="$SCRIPT_DIR/skills_consumers.yaml"

INSTALL_DIR="$HOME/.skills-installed"
COMMUNITY_DIR="$HOME/.skills-community"

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

[[ -f "$SOURCES_CONFIG" ]]   || { echo "ERROR: missing $SOURCES_CONFIG"   >&2; exit 1; }
[[ -f "$CONSUMERS_CONFIG" ]] || { echo "ERROR: missing $CONSUMERS_CONFIG" >&2; exit 1; }

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

# yq raw fetch from sources config; "" if null
sq() {
  local val
  val="$(yq -r "$1" "$SOURCES_CONFIG")"
  [[ "$val" == "null" ]] && echo "" && return
  echo "$val"
}

# yq raw fetch from consumers config
cq() {
  local val
  val="$(yq -r "$1" "$CONSUMERS_CONFIG")"
  [[ "$val" == "null" ]] && echo "" && return
  echo "$val"
}

# Derive source name (used for clone path and SKILL_SOURCE_MAP)
# Priority: explicit name > prefix (if non-empty) > repo basename
derive_source_name() {
  local idx="$1"
  local name prefix repo
  name=$(sq ".repos[$idx].name")
  prefix=$(sq ".repos[$idx].prefix")
  repo=$(sq ".repos[$idx].repo")

  if [[ -n "$name" ]]; then
    echo "$name"
  elif [[ -n "$prefix" ]]; then
    echo "$prefix"
  else
    echo "${repo##*/}"
  fi
}

# Derive clone path; explicit clone_to > ~/.skills-community/{derived_name}
derive_clone_to() {
  local idx="$1"
  local clone_to
  clone_to=$(sq ".repos[$idx].clone_to")
  if [[ -n "$clone_to" ]]; then
    expand_path "$clone_to"
  else
    echo "$COMMUNITY_DIR/$(derive_source_name "$idx")"
  fi
}

# Derive skills scan root (where to look for SKILL.md dirs)
derive_scan_root() {
  local idx="$1"
  local clone_to skills_dir
  clone_to=$(derive_clone_to "$idx")
  skills_dir=$(sq ".repos[$idx].skills_dir")
  if [[ -z "$skills_dir" || "$skills_dir" == "." ]]; then
    echo "$clone_to"
  else
    echo "$clone_to/$skills_dir"
  fi
}

is_repo_skill_excluded() {
  local idx="$1" skill_name="$2"
  local exclude_count
  exclude_count=$(yq ".repos[$idx].exclude | length" "$SOURCES_CONFIG" 2>/dev/null)
  [[ "$exclude_count" == "0" || "$exclude_count" == "null" ]] && return 1
  for ((k = 0; k < exclude_count; k++)); do
    local excluded
    excluded=$(sq ".repos[$idx].exclude[$k]")
    [[ "$excluded" == "$skill_name" ]] && return 0
  done
  return 1
}

get_skill_link_name() {
  local idx="$1" skill_name="$2"
  local prefix
  prefix=$(sq ".repos[$idx].prefix")
  # prefix may be empty string (intentional) or unset; both → no prefix
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
  [[ -d "$root" ]] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | sort
}

cleanup() {
  if [[ -n "$TMPDIR_BASE" && -d "$TMPDIR_BASE" ]]; then
    rm -rf "$TMPDIR_BASE"
  fi
}

# ─── Step 0: clean stale aggregate dirs ───────────────────────────
# Wipes INSTALL_DIR + COMMUNITY_DIR. Sources whose clone_to is OUTSIDE
# COMMUNITY_DIR (e.g. owned: ~/workspace/skills) are NOT touched.

step_clean() {
  log_header "Step 0/4 — clean stale dirs"

  for dir in "$COMMUNITY_DIR" "$INSTALL_DIR"; do
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] would remove: ${dir}"
    elif [[ -e "$dir" || -L "$dir" ]]; then
      rm -rf "$dir"
      log_success "removed: ${dir}"
    fi
  done
}

# ─── Step 1: clone repos + fetch extracts + build ────────────────

step_clone_and_build() {
  log_header "Step 1/4 — clone + build"

  # ── repos ──
  local repo_count
  repo_count=$(yq '.repos | length' "$SOURCES_CONFIG")

  for ((i = 0; i < repo_count; i++)); do
    local sname repo_path repo_url clone_to branch build
    sname=$(derive_source_name "$i")
    repo_path=$(sq ".repos[$i].repo")
    repo_url="https://github.com/${repo_path}.git"
    clone_to=$(derive_clone_to "$i")
    branch=$(sq ".repos[$i].branch")
    branch="${branch:-main}"
    build=$(sq ".repos[$i].build")

    clone_or_pull "$sname" "$repo_url" "$clone_to" "$branch"

    # ── build ──
    if [[ -n "$build" ]]; then
      log_info "${sname}: building..."
      if [[ "$DRY_RUN" == false ]]; then
        (cd "$clone_to" && eval "$build") || {
          log_error "${sname}: build failed"
          continue
        }

        # ── runtime asset symlinks (gstack-style) ──
        local assets_count
        assets_count=$(yq ".repos[$i].runtime_assets | length" "$SOURCES_CONFIG")
        if [[ "$assets_count" != "0" && "$assets_count" != "null" ]]; then
          local skills_dir
          skills_dir=$(sq ".repos[$i].skills_dir")
          local main_skill_dir="${clone_to}/${skills_dir}/${sname}"
          if [[ -d "$main_skill_dir" ]]; then
            for ((j = 0; j < assets_count; j++)); do
              local asset src dst
              asset=$(sq ".repos[$i].runtime_assets[$j]")
              src="${clone_to}/${asset}"
              dst="${main_skill_dir}/${asset}"
              if [[ -d "$src" ]] && { [[ -L "$dst" ]] || [[ ! -e "$dst" ]]; }; then
                ln -snf "$src" "$dst"
              fi
            done
          else
            log_warn "${sname}: main skill dir not found for runtime_assets: ${main_skill_dir}"
          fi
        fi
      else
        log_info "[DRY-RUN] skip build: ${build}"
      fi
      log_success "${sname}: build done"
    fi
  done

  # ── extracts ──
  local extract_count
  extract_count=$(yq '.extracts | length' "$SOURCES_CONFIG" 2>/dev/null)
  if [[ "$extract_count" != "0" && "$extract_count" != "null" ]]; then
    log_info "fetching ${extract_count} extracts..."

    TMPDIR_BASE="$(mktemp -d)"
    trap cleanup EXIT

    local success=0 failed=0

    for ((j = 0; j < extract_count; j++)); do
      local ename erepo esubdir ebranch
      ename=$(sq ".extracts[$j].name")
      erepo=$(sq ".extracts[$j].repo")
      esubdir=$(sq ".extracts[$j].subdir")
      esubdir="${esubdir:-.}"
      ebranch=$(sq ".extracts[$j].branch")
      ebranch="${ebranch:-main}"

      local local_dir="${COMMUNITY_DIR}/${ename}"
      local clone_dir="${TMPDIR_BASE}/${ename}"
      local repo_url="https://github.com/${erepo}.git"

      log_info "  ${ename} <- ${erepo}"

      if [[ "$DRY_RUN" == true ]]; then
        log_info "  [DRY-RUN] would extract"
        continue
      fi

      if ! git clone --depth 1 --branch "$ebranch" --quiet "$repo_url" "$clone_dir" 2>/dev/null; then
        log_error "  ${ename}: clone failed"
        ((failed++)) || true
        continue
      fi

      local src_dir
      if [[ "$esubdir" == "." ]]; then
        src_dir="$clone_dir"
      else
        src_dir="${clone_dir}/${esubdir}"
      fi

      if [[ ! -d "$src_dir" ]]; then
        log_error "  ${ename}: subdir not found: ${esubdir}"
        ((failed++)) || true
        continue
      fi

      local rsync_excludes=("--exclude=.git")
      if [[ "$esubdir" == "." ]]; then
        for excl in README.md README_CN.md LICENSE .gitignore .github; do
          rsync_excludes+=("--exclude=$excl")
        done
      fi

      mkdir -p "$local_dir"
      rsync -av --delete "${rsync_excludes[@]}" "$src_dir/" "$local_dir/" >/dev/null 2>&1

      # patch SKILL.md frontmatter name to match configured name
      local skill_md="${local_dir}/SKILL.md"
      if [[ -f "$skill_md" ]]; then
        sed -i '' "s/^name: .*/name: ${ename}/" "$skill_md"
      fi
      ((success++)) || true
    done

    cleanup
    TMPDIR_BASE=""
    log_success "extracts: ${success} ok, ${failed} failed"
  fi
}

# ─── Step 2: aggregate to INSTALL_DIR ─────────────────────────────

step_aggregate() {
  log_header "Step 2/4 — aggregate -> ${INSTALL_DIR}"

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$INSTALL_DIR"
  fi

  local total_skills=0
  local claimed_skills="|"

  # ── repos ──
  local repo_count
  repo_count=$(yq '.repos | length' "$SOURCES_CONFIG")
  for ((i = 0; i < repo_count; i++)); do
    local sname scan_root
    sname=$(derive_source_name "$i")
    scan_root=$(derive_scan_root "$i")

    [[ -d "$scan_root" ]] || continue

    local count=0
    while IFS= read -r skill_dir; do
      [[ -n "$skill_dir" ]] || continue
      local raw_name link_name
      raw_name="$(basename "$skill_dir")"

      if is_repo_skill_excluded "$i" "$raw_name"; then
        log_info "exclude ${raw_name} from ${sname}"
        continue
      fi

      link_name=$(get_skill_link_name "$i" "$raw_name")

      if [[ "$claimed_skills" == *"|${link_name}|"* ]]; then
        log_warn "keep higher-priority ${link_name}, skip from ${sname}"
        continue
      fi

      claimed_skills="${claimed_skills}${link_name}|"
      SKILL_SOURCE_MAP="${SKILL_SOURCE_MAP}${link_name}=${sname}|"

      if [[ "$DRY_RUN" == false ]]; then
        ln -s "$skill_dir" "${INSTALL_DIR}/${link_name}"
      fi
      ((count++)) || true
      ((total_skills++)) || true
    done < <(discover_skill_dirs "$scan_root")

    [[ "$count" -gt 0 ]] && log_info "source [${sname}]: ${count} skills"
  done

  # ── extracts ──
  local extract_count
  extract_count=$(yq '.extracts | length' "$SOURCES_CONFIG" 2>/dev/null)
  if [[ "$extract_count" != "0" && "$extract_count" != "null" ]]; then
    local count=0
    for ((j = 0; j < extract_count; j++)); do
      local ename
      ename=$(sq ".extracts[$j].name")
      local skill_dir="${COMMUNITY_DIR}/${ename}"
      [[ -d "$skill_dir" && -f "${skill_dir}/SKILL.md" ]] || continue

      if [[ "$claimed_skills" == *"|${ename}|"* ]]; then
        log_warn "keep higher-priority ${ename}, skip extract"
        continue
      fi

      claimed_skills="${claimed_skills}${ename}|"
      SKILL_SOURCE_MAP="${SKILL_SOURCE_MAP}${ename}=extract|"

      if [[ "$DRY_RUN" == false ]]; then
        ln -s "$skill_dir" "${INSTALL_DIR}/${ename}"
      fi
      ((count++)) || true
      ((total_skills++)) || true
    done
    [[ "$count" -gt 0 ]] && log_info "extracts: ${count} skills"
  fi

  log_success "total: ${total_skills} skills aggregated"
}

# ─── Step 3: distribute to consumers ──────────────────────────────

# Compute final skill list for a consumer (uniquified, order-preserving)
# Args: consumer_path
# Output: one skill name per line
resolve_consumer_skills() {
  local consumer_path="$1"
  local only_count add_count

  only_count=$(yq ".consumers[\"${consumer_path}\"].only | length" "$CONSUMERS_CONFIG" 2>/dev/null)
  add_count=$(yq  ".consumers[\"${consumer_path}\"].add  | length" "$CONSUMERS_CONFIG" 2>/dev/null)

  local -a result=()
  local seen="|"

  emit() {
    local n="$1"
    [[ -z "$n" || "$n" == "null" ]] && return
    [[ "$seen" == *"|${n}|"* ]] && return
    seen="${seen}${n}|"
    result+=("$n")
  }

  if [[ "$only_count" != "0" && "$only_count" != "null" ]]; then
    # only mode: use only list, ignore core
    for ((k = 0; k < only_count; k++)); do
      emit "$(yq -r ".consumers[\"${consumer_path}\"].only[$k]" "$CONSUMERS_CONFIG")"
    done
  else
    # default mode: core + add
    local core_count
    core_count=$(yq ".core | length" "$CONSUMERS_CONFIG" 2>/dev/null)
    if [[ "$core_count" != "0" && "$core_count" != "null" ]]; then
      for ((k = 0; k < core_count; k++)); do
        emit "$(yq -r ".core[$k]" "$CONSUMERS_CONFIG")"
      done
    fi
    if [[ "$add_count" != "0" && "$add_count" != "null" ]]; then
      for ((k = 0; k < add_count; k++)); do
        emit "$(yq -r ".consumers[\"${consumer_path}\"].add[$k]" "$CONSUMERS_CONFIG")"
      done
    fi
  fi

  printf '%s\n' "${result[@]}"
}

# Wipe consumer dir safely:
#   - if symlink → just rm
#   - if dir with non-symlink contents → backup
#   - if dir with only symlinks → safe rm
prepare_consumer_dir() {
  local path="$1"

  if [[ -L "$path" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      rm -f "$path"
    fi
  elif [[ -d "$path" ]]; then
    local non_link_count=0
    local entry
    while IFS= read -r entry; do
      [[ -n "$entry" ]] && non_link_count=$((non_link_count + 1))
    done < <(find "$path" -mindepth 1 -maxdepth 1 ! -type l 2>/dev/null)

    if [[ "$non_link_count" -gt 0 ]]; then
      local backup="${path}.backup.$(date +%Y%m%d%H%M%S)"
      log_warn "${path}: contains ${non_link_count} non-symlink entr(ies), backing up to ${backup}"
      if [[ "$DRY_RUN" == false ]]; then
        mv "$path" "$backup"
      fi
    elif [[ "$DRY_RUN" == false ]]; then
      rm -rf "$path"
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$path"
  fi

  return 0
}

step_link() {
  log_header "Step 3/4 — distribute to consumers"

  local consumer_count
  consumer_count=$(yq '.consumers | length' "$CONSUMERS_CONFIG")

  if [[ "$consumer_count" == "0" || "$consumer_count" == "null" ]]; then
    log_warn "no consumers configured"
    return
  fi

  local idx
  for ((idx = 0; idx < consumer_count; idx++)); do
    local raw_path consumer_path
    raw_path=$(yq -r ".consumers | keys | .[$idx]" "$CONSUMERS_CONFIG")
    consumer_path=$(expand_path "$raw_path")

    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$(dirname "$consumer_path")"
    fi

    prepare_consumer_dir "$consumer_path"

    # resolve skills
    local skills=()
    while IFS= read -r s; do
      [[ -n "$s" ]] && skills+=("$s")
    done < <(resolve_consumer_skills "$raw_path")

    local linked=0 missing=0
    for skill in "${skills[@]}"; do
      local target="${INSTALL_DIR}/${skill}"
      if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
          local resolved
          resolved="$(readlink "$target")"
          ln -s "$resolved" "${consumer_path}/${skill}"
        fi
        ((linked++)) || true
      else
        log_warn "${consumer_path}: skill not found: ${skill}"
        ((missing++)) || true
      fi
    done

    if [[ "$missing" -gt 0 ]]; then
      log_info "${consumer_path}: ${linked} linked, ${missing} missing"
    else
      log_success "${consumer_path}: ${linked} skills"
    fi
  done
}

# ─── main ─────────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    Skills Installer                        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

  [[ "$DRY_RUN" == true ]] && log_warn "DRY-RUN mode"

  step_clean
  step_clone_and_build
  step_aggregate
  step_link

  echo ""
  log_success "all done!"
}

main "$@"
