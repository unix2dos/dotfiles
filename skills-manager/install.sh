#!/bin/bash
# ============================================
# Skills 一键安装
# ============================================
# 读取 config.yaml，完成：
#   clone → build → aggregate → 按目录分发 → 安装原生扩展
#
# 用法:
#   bash install.sh            # 安装/更新全部
#   bash install.sh --preview         # 查看最终目录与扩展状态
#   bash install.sh --preview --full  # 展开完整 Skill 名称
#   bash install.sh --dry-run         # 查看将执行的变更
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.yaml"

INSTALL_DIR="$HOME/.skills-installed"
COMMUNITY_DIR="$HOME/.skills-community"

DRY_RUN=false
PREVIEW=false
PREVIEW_FULL=false
TMPDIR_BASE=""
DIFF_DIR=""

# skill_link_name -> source_name mapping (populated in step_link)
# Format: "|link_name=source_name|..." (bash 3.x compatible)
SKILL_SOURCE_MAP="|"
SKILL_DIR_MAP="|"
SOURCE_COUNTS="|"
SOURCE_DISCOVERED="|"
SOURCE_EXCLUDED="|"
ACTIVE_SOURCES="|"
MISSING_SOURCES="|"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --preview) PREVIEW=true ;;
    --full) PREVIEW_FULL=true ;;
    -h|--help)
      echo "Usage: bash install.sh [--dry-run | --preview [--full]]"
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$DRY_RUN" == true && "$PREVIEW" == true ]]; then
  echo "ERROR: --dry-run and --preview are mutually exclusive" >&2
  exit 1
fi
if [[ "$PREVIEW_FULL" == true && "$PREVIEW" == false ]]; then
  echo "ERROR: --full requires --preview" >&2
  exit 1
fi

# ─── check ────────────────────────────────────────────────────────

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq not found. Run: brew install yq" >&2
  exit 1
fi

[[ -f "$CONFIG" ]] || { echo "ERROR: missing $CONFIG" >&2; exit 1; }
yq -e '.install and .extensions and .presets and .sources' "$CONFIG" >/dev/null || {
  echo "ERROR: config.yaml must define install, extensions, presets, and sources" >&2
  exit 1
}

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

# yq raw fetch from unified config; "" if null
q() {
  local val
  val="$(yq -r "$1" "$CONFIG")"
  [[ "$val" == "null" ]] && echo "" && return
  echo "$val"
}

source_q() {
  local source_name="$1" field="$2"
  q ".sources[\"${source_name}\"].${field}"
}

source_exists() {
  yq -e ".sources[\"$1\"]" "$CONFIG" >/dev/null 2>&1
}

mark_active_source() {
  local source_name="$1"
  [[ -z "$source_name" || "$source_name" == "null" ]] && return
  source_exists "$source_name" || {
    echo "ERROR: unknown Source: $source_name" >&2
    return 1
  }
  [[ "$ACTIVE_SOURCES" == *"|${source_name}|"* ]] || ACTIVE_SOURCES="${ACTIVE_SOURCES}${source_name}|"
}

mark_named_skill_source() {
  local skill_name="$1"
  # Single-Skill Sources conventionally share the final Skill name. Skills
  # exported by an already-active multi-Skill Source need no extra activation.
  source_exists "$skill_name" && mark_active_source "$skill_name"
  return 0
}

build_active_sources() {
  local raw_path preset count i source_name
  while IFS= read -r raw_path; do
    [[ -n "$raw_path" ]] || continue
    preset=$(q ".install[\"${raw_path}\"].preset")
    [[ -n "$preset" ]] || { echo "ERROR: ${raw_path} is missing preset" >&2; return 1; }
    yq -e ".presets[\"${preset}\"]" "$CONFIG" >/dev/null 2>&1 || {
      echo "ERROR: ${raw_path} references unknown Preset: ${preset}" >&2
      return 1
    }

    count=$(yq ".presets[\"${preset}\"].sources | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      mark_active_source "$(q ".presets[\"${preset}\"].sources[$i]")"
    done

    count=$(yq ".presets[\"${preset}\"].skills | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      mark_named_skill_source "$(q ".presets[\"${preset}\"].skills[$i]")"
    done

    count=$(yq ".install[\"${raw_path}\"].add | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      mark_named_skill_source "$(q ".install[\"${raw_path}\"].add[$i]")"
    done
  done < <(yq -r '.install | to_entries | .[].key' "$CONFIG")

}

derive_clone_to() {
  local source_name="$1" checkout
  checkout=$(source_q "$source_name" checkout)
  if [[ -n "$checkout" ]]; then
    expand_path "$checkout"
  else
    echo "$COMMUNITY_DIR/$source_name"
  fi
}

derive_scan_root() {
  local source_name="$1" clone_to skills_dir
  clone_to=$(derive_clone_to "$source_name")
  skills_dir=$(source_q "$source_name" skills_dir)
  if [[ -z "$skills_dir" || "$skills_dir" == "." ]]; then
    echo "$clone_to"
  else
    echo "$clone_to/$skills_dir"
  fi
}

is_source_skill_excluded() {
  local source_name="$1" skill_name="$2"
  local include_count exclude_count k

  include_count=$(yq ".sources[\"${source_name}\"].include | length" "$CONFIG" 2>/dev/null)
  if [[ "$include_count" != "0" && "$include_count" != "null" ]]; then
    local included=false
    for ((k = 0; k < include_count; k++)); do
      local allowed
      allowed=$(q ".sources[\"${source_name}\"].include[$k]")
      if [[ "$allowed" == "$skill_name" ]]; then
        included=true
        break
      fi
    done
    [[ "$included" == false ]] && return 0
  fi

  exclude_count=$(yq ".sources[\"${source_name}\"].exclude | length" "$CONFIG" 2>/dev/null)
  [[ "$exclude_count" == "0" || "$exclude_count" == "null" ]] && return 1
  for ((k = 0; k < exclude_count; k++)); do
    local excluded
    excluded=$(q ".sources[\"${source_name}\"].exclude[$k]")
    [[ "$excluded" == "$skill_name" ]] && return 0
  done
  return 1
}

configure_sparse_checkout() {
  local source_name="$1" dest="$2"
  local include_count k
  include_count=$(yq ".sources[\"${source_name}\"].include | length" "$CONFIG" 2>/dev/null)
  [[ "$include_count" == "0" || "$include_count" == "null" ]] && return 0

  local skills_dir
  skills_dir=$(source_q "$source_name" skills_dir)

  local -a sparse_paths=()
  for ((k = 0; k < include_count; k++)); do
    local included
    included=$(q ".sources[\"${source_name}\"].include[$k]")
    if [[ -z "$skills_dir" || "$skills_dir" == "." ]]; then
      sparse_paths+=("$included")
    else
      sparse_paths+=("${skills_dir}/${included}")
    fi
  done

  git -C "$dest" sparse-checkout set "${sparse_paths[@]}"
  log_info "sparse checkout: ${include_count} included skills"
}

clone_or_pull() {
  local label="$1" repo_url="$2" dest="$3" branch="${4:-main}" source_name="${5:-}"
  local include_count=0
  if [[ -n "$source_name" ]]; then
    include_count=$(yq ".sources[\"${source_name}\"].include | length" "$CONFIG" 2>/dev/null)
    [[ "$include_count" == "null" ]] && include_count=0
  fi

  if [[ -d "$dest/.git" ]]; then
    log_info "${label}: pulling..."
    if [[ "$DRY_RUN" == false ]]; then
      if [[ "$include_count" != "0" ]]; then
        configure_sparse_checkout "$source_name" "$dest"
      fi
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
      if [[ "$include_count" != "0" ]]; then
        git clone --depth 1 --filter=blob:none --sparse --branch "$branch" "$repo_url" "$dest" --quiet
        configure_sparse_checkout "$source_name" "$dest"
      else
        git clone --depth 1 --branch "$branch" "$repo_url" "$dest" --quiet
      fi
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

# ─── snapshot Destination dirs (for diff) ──────────────────────────

snapshot_destinations() {
  DIFF_DIR="$(mktemp -d)"
  local destination_count
  destination_count=$(yq '.install | length' "$CONFIG")
  for ((idx = 0; idx < destination_count; idx++)); do
    local raw_path destination_path
    raw_path=$(yq -r ".install | keys | .[$idx]" "$CONFIG")
    destination_path=$(expand_path "$raw_path")
    if [[ -d "$destination_path" ]]; then
      ls -1 "$destination_path" 2>/dev/null | sort > "${DIFF_DIR}/${idx}_old"
    else
      touch "${DIFF_DIR}/${idx}_old"
    fi
  done
}

# ─── Step 0: clean stale aggregate dirs ───────────────────────────
# Wipes INSTALL_DIR + COMMUNITY_DIR. Sources whose clone_to is OUTSIDE
# COMMUNITY_DIR (e.g. owned: ~/workspace/skills) are NOT touched.

step_clean() {
  log_header "Step 0/6 — clean stale dirs"

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
  log_header "Step 1/6 — clone + build"

  local source_name github repo_url checkout branch single_skill build
  local single_count=0 single_ok=0 single_failed=0

  while IFS= read -r source_name; do
    [[ -n "$source_name" ]] || continue
    [[ "$ACTIVE_SOURCES" == *"|${source_name}|"* ]] || continue

    github=$(source_q "$source_name" github)
    [[ -n "$github" ]] || { log_error "Source '$source_name' is missing github"; return 1; }
    repo_url="https://github.com/${github}.git"
    branch=$(source_q "$source_name" branch)
    branch="${branch:-main}"
    single_skill=$(source_q "$source_name" skill)

    if [[ -n "$single_skill" ]]; then
      ((single_count++)) || true
      [[ -n "$TMPDIR_BASE" ]] || {
        TMPDIR_BASE="$(mktemp -d)"
        trap cleanup EXIT
      }

      local local_dir="${COMMUNITY_DIR}/${source_name}"
      local clone_dir="${TMPDIR_BASE}/${source_name}"
      log_info "${source_name} <- ${github}/${single_skill}"

      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] would extract single Skill"
        continue
      fi

      if ! git clone --depth 1 --branch "$branch" --quiet "$repo_url" "$clone_dir"; then
        log_error "${source_name}: clone failed (repo: ${github}, branch: ${branch})"
        ((single_failed++)) || true
        continue
      fi

      local src_dir
      if [[ "$single_skill" == "." ]]; then src_dir="$clone_dir"; else src_dir="$clone_dir/$single_skill"; fi
      if [[ ! -d "$src_dir" ]]; then
        log_error "${source_name}: Skill path not found: ${single_skill}"
        ((single_failed++)) || true
        continue
      fi

      local rsync_excludes=("--exclude=.git")
      if [[ "$single_skill" == "." ]]; then
        for excl in README.md README_CN.md LICENSE .gitignore .github; do
          rsync_excludes+=("--exclude=$excl")
        done
      fi
      mkdir -p "$local_dir"
      rsync -av --delete "${rsync_excludes[@]}" "$src_dir/" "$local_dir/" >/dev/null 2>&1
      [[ ! -f "$local_dir/SKILL.md" ]] || sed -i '' "s/^name: .*/name: ${source_name}/" "$local_dir/SKILL.md"
      ((single_ok++)) || true
      continue
    fi

    checkout=$(derive_clone_to "$source_name")
    clone_or_pull "$source_name" "$repo_url" "$checkout" "$branch" "$source_name"

    build=$(source_q "$source_name" build)
    if [[ -n "$build" ]]; then
      log_info "${source_name}: building..."
      if [[ "$DRY_RUN" == false ]]; then
        (cd "$checkout" && eval "$build") || { log_error "${source_name}: build failed"; return 1; }

        local assets_count skills_dir main_skill_dir
        assets_count=$(yq ".sources[\"${source_name}\"].runtime_assets | length" "$CONFIG" 2>/dev/null)
        if [[ "$assets_count" != "0" && "$assets_count" != "null" ]]; then
          skills_dir=$(source_q "$source_name" skills_dir)
          main_skill_dir="${checkout}/${skills_dir}/${source_name}"
          if [[ -d "$main_skill_dir" ]]; then
            for ((j = 0; j < assets_count; j++)); do
              local asset src dst
              asset=$(q ".sources[\"${source_name}\"].runtime_assets[$j]")
              src="${checkout}/${asset}"
              dst="${main_skill_dir}/${asset}"
              if [[ -d "$src" ]] && { [[ -L "$dst" ]] || [[ ! -e "$dst" ]]; }; then ln -snf "$src" "$dst"; fi
            done
          else
            log_warn "${source_name}: main Skill dir not found for runtime_assets: ${main_skill_dir}"
          fi
        fi
      else
        log_info "[DRY-RUN] skip build: ${build}"
      fi
      log_success "${source_name}: build done"
    fi
  done < <(yq -r '.sources | to_entries | .[].key' "$CONFIG")

  if [[ "$single_count" -gt 0 ]]; then
    cleanup
    TMPDIR_BASE=""
    if [[ "$DRY_RUN" == false ]]; then
      log_success "single Skills: ${single_ok} ok, ${single_failed} failed"
      [[ "$single_failed" -eq 0 ]] || return 1
    fi
  fi
}

# ─── Step 2: aggregate to INSTALL_DIR ─────────────────────────────

step_aggregate() {
  [[ "$PREVIEW" == true ]] || log_header "Step 2/6 — aggregate -> ${INSTALL_DIR}"

  if [[ "$DRY_RUN" == false && "$PREVIEW" == false ]]; then
    mkdir -p "$INSTALL_DIR"
  fi

  SKILL_SOURCE_MAP="|"
  SKILL_DIR_MAP="|"
  SOURCE_COUNTS="|"
  SOURCE_DISCOVERED="|"
  SOURCE_EXCLUDED="|"
  MISSING_SOURCES="|"

  local total_skills=0
  local claimed_skills="|"
  local source_name single_skill scan_root skill_dir skill_name
  local count discovered excluded

  while IFS= read -r source_name; do
    [[ -n "$source_name" ]] || continue
    [[ "$ACTIVE_SOURCES" == *"|${source_name}|"* ]] || continue

    count=0
    discovered=0
    excluded=0
    single_skill=$(source_q "$source_name" skill)

    if [[ -n "$single_skill" ]]; then
      skill_dir="$COMMUNITY_DIR/$source_name"
      if [[ ! -d "$skill_dir" || ! -f "$skill_dir/SKILL.md" ]]; then
        MISSING_SOURCES="${MISSING_SOURCES}${source_name}|"
      else
        discovered=1
        skill_name="$source_name"
        claimed_skills="${claimed_skills}${skill_name}|"
        SKILL_SOURCE_MAP="${SKILL_SOURCE_MAP}${skill_name}=${source_name}|"
        SKILL_DIR_MAP="${SKILL_DIR_MAP}${skill_name}=${skill_dir}|"
        if [[ "$DRY_RUN" == false && "$PREVIEW" == false ]]; then ln -s "$skill_dir" "$INSTALL_DIR/$skill_name"; fi
        count=1
        ((total_skills++)) || true
      fi
    else
      scan_root=$(derive_scan_root "$source_name")
      if [[ ! -d "$scan_root" ]]; then
        MISSING_SOURCES="${MISSING_SOURCES}${source_name}|"
      else
        while IFS= read -r skill_dir; do
          [[ -n "$skill_dir" ]] || continue
          ((discovered++)) || true
          skill_name="$(basename "$skill_dir")"

          if is_source_skill_excluded "$source_name" "$skill_name"; then
            ((excluded++)) || true
            [[ "$PREVIEW" == true ]] || log_info "exclude ${skill_name} from ${source_name}"
            continue
          fi
          if [[ "$claimed_skills" == *"|${skill_name}|"* ]]; then
            log_warn "keep higher-priority ${skill_name}, skip from ${source_name}"
            continue
          fi

          claimed_skills="${claimed_skills}${skill_name}|"
          SKILL_SOURCE_MAP="${SKILL_SOURCE_MAP}${skill_name}=${source_name}|"
          SKILL_DIR_MAP="${SKILL_DIR_MAP}${skill_name}=${skill_dir}|"
          if [[ "$DRY_RUN" == false && "$PREVIEW" == false ]]; then ln -s "$skill_dir" "$INSTALL_DIR/$skill_name"; fi
          ((count++)) || true
          ((total_skills++)) || true
        done < <(discover_skill_dirs "$scan_root")
      fi
    fi

    SOURCE_COUNTS="${SOURCE_COUNTS}${source_name}=${count}|"
    SOURCE_DISCOVERED="${SOURCE_DISCOVERED}${source_name}=${discovered}|"
    SOURCE_EXCLUDED="${SOURCE_EXCLUDED}${source_name}=${excluded}|"
    if [[ "$count" -gt 0 && "$PREVIEW" == false ]]; then log_info "source [${source_name}]: ${count} Skills"; fi
  done < <(yq -r '.sources | to_entries | .[].key' "$CONFIG")

  [[ "$PREVIEW" == true ]] || log_success "total: ${total_skills} Skills aggregated"
}

# ─── Step 3: distribute to Destinations ───────────────────────────

# Expand `source:<name>` into the list of skill names that came from that source.
# Relies on SKILL_SOURCE_MAP populated by step_aggregate. Output: one skill per line (sorted).
expand_source_ref() {
  local source_name="$1"
  local map="${SKILL_SOURCE_MAP#|}"
  local -a entries=()
  IFS='|' read -ra entries <<< "$map"
  local entry sk sn
  {
    for entry in ${entries[@]+"${entries[@]}"}; do
      if [[ -n "$entry" ]]; then
        sk="${entry%%=*}"
        sn="${entry##*=}"
        if [[ "$sn" == "$source_name" ]]; then
          echo "$sk"
        fi
      fi
    done
  } | sort
  return 0
}

# Resolve a Preset into final Skill names.
resolve_preset_skills() {
  local preset="$1" count i source_name skill_name
  {
    count=$(yq ".presets[\"${preset}\"].sources | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      source_name=$(q ".presets[\"${preset}\"].sources[$i]")
      expand_source_ref "$source_name"
    done

    count=$(yq ".presets[\"${preset}\"].skills | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      skill_name=$(q ".presets[\"${preset}\"].skills[$i]")
      if [[ "$SKILL_DIR_MAP" == *"|${skill_name}="* ]]; then
        echo "$skill_name"
      else
        log_warn "Preset '${preset}': Skill not available: ${skill_name}" >&2
      fi
    done
  } | awk 'NF && !seen[$0]++'
}

# Resolve a Destination: one Preset plus optional individual Skills.
resolve_destination_skills() {
  local destination="$1" preset count i skill_name
  preset=$(q ".install[\"${destination}\"].preset")
  {
    resolve_preset_skills "$preset"
    count=$(yq ".install[\"${destination}\"].add | length" "$CONFIG" 2>/dev/null)
    [[ "$count" == "null" ]] && count=0
    for ((i = 0; i < count; i++)); do
      skill_name=$(q ".install[\"${destination}\"].add[$i]")
      if [[ "$SKILL_DIR_MAP" == *"|${skill_name}="* ]]; then
        echo "$skill_name"
      else
        log_warn "Destination '${destination}': Skill not available: ${skill_name}" >&2
      fi
    done
  } | awk 'NF && !seen[$0]++'
}

map_value() {
  local map="$1" key="$2" entries entry
  local -a parts=()
  entries="${map#|}"
  IFS='|' read -ra parts <<< "$entries"
  for entry in ${parts[@]+"${parts[@]}"}; do
    [[ "${entry%%=*}" == "$key" ]] && { echo "${entry#*=}"; return 0; }
  done
  return 1
}

# Synchronize a Destination directory in place:
#   - remove old managed symlinks
#   - leave real entries untouched because they are managed externally
#   - never move the whole Destination directory
prepare_destination_dir() {
  local path="$1"
  local backup="${path}.backup.$(date +%Y%m%d%H%M%S).$$"

  if [[ -L "$path" ]]; then
    log_warn "${path}: Destination root is a symlink; replacing it with a directory"
    if [[ "$DRY_RUN" == false ]]; then
      rm -f "$path"
    fi
  elif [[ -d "$path" ]]; then
    local link_count=0 unmanaged_count=0
    local entry
    while IFS= read -r entry; do
      [[ -n "$entry" ]] || continue

      if [[ -L "$entry" ]]; then
        ((link_count++)) || true
        if [[ "$DRY_RUN" == false ]]; then
          rm -f "$entry"
        fi
      else
        ((unmanaged_count++)) || true
      fi
    done < <(find "$path" -mindepth 1 -maxdepth 1 -print 2>/dev/null | sort)

    if [[ "$unmanaged_count" -gt 0 ]]; then
      log_info "${path}: leaving ${unmanaged_count} externally managed real entr(ies) untouched"
    fi
    if [[ "$link_count" -gt 0 ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] ${path}: would replace ${link_count} managed symlink(s) in place"
      else
        log_info "${path}: removed ${link_count} old managed symlink(s)"
      fi
    fi
  elif [[ -e "$path" ]]; then
    log_warn "${path}: Destination root is not a directory; backing it up to ${backup}"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$path" "$backup"
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$path"
  fi

  return 0
}

step_link() {
  log_header "Step 3/6 — distribute to Destinations"

  local destination_count
  destination_count=$(yq '.install | length' "$CONFIG")

  if [[ "$destination_count" == "0" || "$destination_count" == "null" ]]; then
    log_warn "no Destinations configured"
    return
  fi

  local idx
  for ((idx = 0; idx < destination_count; idx++)); do
    local raw_path destination_path
    raw_path=$(yq -r ".install | keys | .[$idx]" "$CONFIG")
    destination_path=$(expand_path "$raw_path")

    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$(dirname "$destination_path")"
    fi

    prepare_destination_dir "$destination_path"

    # resolve skills
    local skills=()
    while IFS= read -r s; do
      [[ -n "$s" ]] && skills+=("$s")
    done < <(resolve_destination_skills "$raw_path")

    local linked=0 missing=0 conflicts=0
    for skill in ${skills[@]+"${skills[@]}"}; do
      local target
      target=$(map_value "$SKILL_DIR_MAP" "$skill" 2>/dev/null || true)
      if [[ -n "$target" && -e "$target" ]]; then
        if [[ -e "${destination_path}/${skill}" && ! -L "${destination_path}/${skill}" ]]; then
          log_warn "${destination_path}: externally managed entry conflicts with managed Skill: ${skill} (skip)"
          ((conflicts++)) || true
          continue
        fi
        if [[ "$DRY_RUN" == false ]]; then
          if [[ -e "${destination_path}/${skill}" || -L "${destination_path}/${skill}" ]]; then
            log_warn "${destination_path}: Destination entry still exists: ${skill} (skip)"
            ((conflicts++)) || true
            continue
          fi
          ln -s "$target" "${destination_path}/${skill}"
        fi
        ((linked++)) || true
      else
        log_warn "${destination_path}: Skill not found: ${skill}"
        ((missing++)) || true
      fi
    done

    if [[ "$missing" -gt 0 || "$conflicts" -gt 0 ]]; then
      log_info "${destination_path}: ${linked} linked, ${missing} missing, ${conflicts} conflict(s)"
    else
      log_success "${destination_path}: ${linked} Skills"
    fi
  done
}

# ─── Step 4: diff report ──────────────────────────────────────────

step_diff() {
  if [[ "$DRY_RUN" == true ]]; then
    [[ -z "$DIFF_DIR" || ! -d "$DIFF_DIR" ]] || rm -rf "$DIFF_DIR"
    DIFF_DIR=""
    return
  fi
  [[ -z "$DIFF_DIR" || ! -d "$DIFF_DIR" ]] && return

  log_header "Step 4/6 — changes"

  local destination_count has_changes=false
  destination_count=$(yq '.install | length' "$CONFIG")

  for ((idx = 0; idx < destination_count; idx++)); do
    local raw_path destination_path
    raw_path=$(yq -r ".install | keys | .[$idx]" "$CONFIG")
    destination_path=$(expand_path "$raw_path")

    if [[ -d "$destination_path" ]]; then
      ls -1 "$destination_path" 2>/dev/null | sort > "${DIFF_DIR}/${idx}_new"
    else
      touch "${DIFF_DIR}/${idx}_new"
    fi

    local added removed
    added=$(comm -13 "${DIFF_DIR}/${idx}_old" "${DIFF_DIR}/${idx}_new")
    removed=$(comm -23 "${DIFF_DIR}/${idx}_old" "${DIFF_DIR}/${idx}_new")

    if [[ -n "$added" || -n "$removed" ]]; then
      has_changes=true
      log_info "${raw_path}:"
      if [[ -n "$added" ]]; then
        while IFS= read -r s; do
          [[ -n "$s" ]] && echo -e "  ${GREEN}+ ${s}${NC}"
        done <<< "$added"
      fi
      if [[ -n "$removed" ]]; then
        while IFS= read -r s; do
          [[ -n "$s" ]] && echo -e "  ${RED}- ${s}${NC}"
        done <<< "$removed"
      fi
    fi
  done

  if [[ "$has_changes" == false ]]; then
    log_success "no changes across all Destinations"
  fi

  rm -rf "$DIFF_DIR"
  DIFF_DIR=""
}

# ─── Preview ──────────────────────────────────────────────────────

count_lines() { awk 'NF { n++ } END { print n + 0; }'; }

external_skill_names() {
  local destination="$1" entry
  [[ -d "$destination" ]] || return 0
  while IFS= read -r entry; do
    [[ -L "$entry" ]] && continue
    [[ -f "$entry/SKILL.md" ]] && basename "$entry"
  done < <(find "$destination" -mindepth 1 -maxdepth 1 -print 2>/dev/null | sort)
}

step_preview() {
  step_aggregate

  echo "PRESETS"
  local preset source_count source_name count discovered excluded skills individual_count
  while IFS= read -r preset; do
    [[ -n "$preset" ]] || continue
    skills=$(resolve_preset_skills "$preset")
    echo ""
    echo "${preset} — $(printf '%s\n' "$skills" | count_lines) managed Skills"

    source_count=$(yq ".presets[\"${preset}\"].sources | length" "$CONFIG" 2>/dev/null)
    [[ "$source_count" == "null" ]] && source_count=0
    for ((i = 0; i < source_count; i++)); do
      source_name=$(q ".presets[\"${preset}\"].sources[$i]")
      count=$(map_value "$SOURCE_COUNTS" "$source_name" 2>/dev/null || echo 0)
      discovered=$(map_value "$SOURCE_DISCOVERED" "$source_name" 2>/dev/null || echo 0)
      excluded=$(map_value "$SOURCE_EXCLUDED" "$source_name" 2>/dev/null || echo 0)
      if [[ "$MISSING_SOURCES" == *"|${source_name}|"* ]]; then
        printf '  source %-30s not available\n' "$source_name"
      elif [[ "$excluded" -gt 0 ]]; then
        printf '  source %-30s %3d  (%d discovered, %d excluded)\n' "$source_name" "$count" "$discovered" "$excluded"
      else
        printf '  source %-30s %3d\n' "$source_name" "$count"
      fi
    done
    individual_count=$(yq ".presets[\"${preset}\"].skills | length" "$CONFIG" 2>/dev/null)
    [[ "$individual_count" == "null" ]] && individual_count=0
    printf '  specific Skills%24d\n' "$individual_count"
    if [[ "$individual_count" -gt 0 ]]; then
      printf '    %s\n' "$(yq -r ".presets[\"${preset}\"].skills | join(\", \")" "$CONFIG")"
    fi
    if [[ "$PREVIEW_FULL" == true ]]; then
      printf '%s\n' "$skills" | while IFS= read -r skill; do [[ -n "$skill" ]] && echo "    - $skill"; done
    fi
  done < <(yq -r '.presets | to_entries | .[].key' "$CONFIG")

  echo ""
  echo "DESTINATIONS"
  local raw_path destination preset_name add_names expected external managed_count external_count final_count
  while IFS= read -r raw_path; do
    [[ -n "$raw_path" ]] || continue
    destination=$(expand_path "$raw_path")
    preset_name=$(q ".install[\"${raw_path}\"].preset")
    add_names=$(yq -r ".install[\"${raw_path}\"].add // [] | join(\", \")" "$CONFIG")
    expected=$(resolve_destination_skills "$raw_path")
    external=$(external_skill_names "$destination")
    managed_count=$(printf '%s\n' "$expected" | count_lines)
    external_count=$(printf '%s\n' "$external" | count_lines)
    final_count=$(printf '%s\n%s\n' "$expected" "$external" | awk 'NF && !seen[$0]++ { n++ } END { print n + 0 }')

    echo ""
    echo "$raw_path"
    echo "  preset: $preset_name"
    [[ -z "$add_names" ]] || echo "  add: $add_names"
    echo "  managed: $managed_count"
    [[ "$external_count" -eq 0 ]] || echo "  external kept: $external_count"
    echo "  final visible: $final_count"
    if [[ "$PREVIEW_FULL" == true ]]; then
      printf '%s\n' "$expected" | while IFS= read -r skill; do [[ -n "$skill" ]] && echo "    - $skill"; done
      if [[ "$external_count" -gt 0 ]]; then
        echo "  external:"
        printf '%s\n' "$external" | while IFS= read -r skill; do [[ -n "$skill" ]] && echo "    - $skill"; done
      fi
    fi
  done < <(yq -r '.install | to_entries | .[].key' "$CONFIG")

  echo ""
  echo "EXTENSIONS"
  step_extensions preview

  local unused=false
  while IFS= read -r source_name; do
    [[ -n "$source_name" ]] || continue
    if [[ "$ACTIVE_SOURCES" != *"|${source_name}|"* ]]; then
      if [[ "$unused" == false ]]; then echo ""; echo "UNUSED SOURCES"; unused=true; fi
      echo "  $source_name — configured, not selected"
    fi
  done < <(yq -r '.sources | to_entries | .[].key' "$CONFIG")

  if [[ "$MISSING_SOURCES" != "|" ]]; then
    echo ""
    echo "MISSING SOURCES"
    while IFS= read -r source_name; do
      [[ "$MISSING_SOURCES" == *"|${source_name}|"* ]] && echo "  $source_name — not available locally"
    done < <(yq -r '.sources | to_entries | .[].key' "$CONFIG")
  fi
}

# ─── Step 5: host-native Extensions ───────────────────────────────

step_extensions() {
  local action="$1" extension script host_count i host
  local -a hosts=()

  [[ "$action" == "preview" ]] || log_header "Step 5/6 — native Extensions"
  while IFS= read -r extension; do
    [[ -n "$extension" ]] || continue
    script="$SCRIPT_DIR/installers/${extension}.sh"
    [[ -f "$script" ]] || { log_error "missing Extension Installer: $script"; return 1; }

    hosts=()
    host_count=$(yq ".extensions[\"${extension}\"].hosts | length" "$CONFIG" 2>/dev/null)
    [[ "$host_count" == "null" ]] && host_count=0
    for ((i = 0; i < host_count; i++)); do
      host=$(q ".extensions[\"${extension}\"].hosts[$i]")
      [[ -n "$host" ]] && hosts+=("$host")
    done

    [[ "$action" == "preview" ]] && echo "" && echo "$extension"
    bash "$script" "$action" "${hosts[@]}"
  done < <(yq -r '.extensions | to_entries | .[].key' "$CONFIG")
}

# ─── main ─────────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    Skills Installer                        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

  [[ "$DRY_RUN" == true ]] && log_warn "DRY-RUN mode"
  build_active_sources

  if [[ "$PREVIEW" == true ]]; then
    step_preview
    exit 0
  fi

  snapshot_destinations
  step_clean
  step_clone_and_build
  step_aggregate
  step_link
  step_diff
  if [[ "$DRY_RUN" == true ]]; then
    step_extensions dry-run
  else
    step_extensions install
  fi

  echo ""
  log_success "all done!"
}

main "$@"
