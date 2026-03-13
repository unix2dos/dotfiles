#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/agents/skills/sources.sh"
INSTALL_SCRIPT="$ROOT_DIR/agents/skills/install.sh"
README_SCRIPT="$ROOT_DIR/agents/skills/README.md"
ROOT_README="$ROOT_DIR/README.md"

CONSUMER_LINKS=(
  ".agents/skills"
  ".claude/skills"
  ".codex/skills"
  ".config/opencode/skills"
  ".config/alma/skills"
  ".gemini/antigravity/skills"
  ".openclaw/skills"
)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [ "$actual" != "$expected" ]; then
    fail "$message: expected '$expected', got '$actual'"
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"

  if ! rg -q --fixed-strings "$pattern" "$file"; then
    fail "missing pattern '$pattern' in $file"
  fi
}

run_manifest_test() {
  local sandbox
  sandbox="$(mktemp -d)"

  local own_root="$sandbox/own"
  local generated_root="$sandbox/generated"
  local third_party_root="$sandbox/third-party"
  mkdir -p \
    "$own_root/alpha" \
    "$generated_root/ed3d-omega" \
    "$third_party_root/brainstorming"
  touch \
    "$own_root/alpha/SKILL.md" \
    "$generated_root/ed3d-omega/SKILL.md" \
    "$third_party_root/brainstorming/SKILL.md"

  local output
  output="$(
    OWNED_SKILLS_ROOT="$own_root" \
    GENERATED_SKILLS_ROOT="$generated_root" \
    THIRD_PARTY_SKILLS_ROOT="$third_party_root" \
    bash -c "source '$SOURCE_SCRIPT'; list_skill_sources"
  )"

  local expected="owned	$own_root
generated	$generated_root
third-party	$third_party_root"
  assert_eq "$output" "$expected" "source order should be deterministic"

  rm -rf "$sandbox"
}

run_installer_test() {
  local sandbox
  sandbox="$(mktemp -d)"

  local fake_home="$sandbox/home"
  local own_root="$sandbox/own"
  local generated_root="$sandbox/generated"
  local third_party_root="$sandbox/third-party"
  mkdir -p "$fake_home" "$own_root/alpha" "$generated_root/ed3d-omega" "$third_party_root/brainstorming"
  touch \
    "$own_root/alpha/SKILL.md" \
    "$generated_root/ed3d-omega/SKILL.md" \
    "$third_party_root/brainstorming/SKILL.md"

  local relative_link
  for relative_link in "${CONSUMER_LINKS[@]}"; do
    mkdir -p "$fake_home/$relative_link"
    touch "$fake_home/$relative_link/old"
  done

  HOME="$fake_home" \
  TIMESTAMP="20260313190001" \
  OWNED_SKILLS_ROOT="$own_root" \
  GENERATED_SKILLS_ROOT="$generated_root" \
  THIRD_PARTY_SKILLS_ROOT="$third_party_root" \
  bash "$INSTALL_SCRIPT"

  for relative_link in "${CONSUMER_LINKS[@]}"; do
    assert_eq "$(readlink "$fake_home/$relative_link")" "$fake_home/.skills-installed" "$relative_link link target"
    test -e "$fake_home/$relative_link.backup" || fail "expected backup for $relative_link"
  done

  assert_eq "$(readlink "$fake_home/.skills-installed/alpha")" "$own_root/alpha" "owned skill target"
  assert_eq "$(readlink "$fake_home/.skills-installed/ed3d-omega")" "$generated_root/ed3d-omega" "generated skill target"
  assert_eq "$(readlink "$fake_home/.skills-installed/brainstorming")" "$third_party_root/brainstorming" "third-party skill target"

  local before_backups=()
  for relative_link in "${CONSUMER_LINKS[@]}"; do
    before_backups+=("$(readlink "$fake_home/$relative_link.backup")")
  done

  HOME="$fake_home" \
  TIMESTAMP="20260313190002" \
  OWNED_SKILLS_ROOT="$own_root" \
  GENERATED_SKILLS_ROOT="$generated_root" \
  THIRD_PARTY_SKILLS_ROOT="$third_party_root" \
  bash "$INSTALL_SCRIPT"

  local index=0
  for relative_link in "${CONSUMER_LINKS[@]}"; do
    assert_eq "$(readlink "$fake_home/$relative_link.backup")" "${before_backups[$index]}" "installer should not rotate backup when link is already correct for $relative_link"
    index=$((index + 1))
  done

  rm -rf "$sandbox"
}

run_docs_test() {
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.skills-installed"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/workspace/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.codex/superpowers"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/workspace/compat-ed3d"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.claude/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.config/opencode/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.config/alma/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.gemini/antigravity/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.openclaw/skills"
  assert_file_contains "$README_SCRIPT" "install.sh"
  assert_file_contains "$README_SCRIPT" "备份"
  assert_file_contains "$README_SCRIPT" "新增来源"
  assert_file_contains "$ROOT_README" "agents/skills/README.md"
}

main() {
  test -f "$SOURCE_SCRIPT" || fail "missing $SOURCE_SCRIPT"
  test -f "$INSTALL_SCRIPT" || fail "missing $INSTALL_SCRIPT"
  test -f "$README_SCRIPT" || fail "missing $README_SCRIPT"

  run_manifest_test
  run_installer_test
  run_docs_test

  echo "PASS"
}

main "$@"
