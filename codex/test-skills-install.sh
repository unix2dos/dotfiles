#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/codex/skills-sources.sh"
INSTALL_SCRIPT="$ROOT_DIR/codex/skills-install.sh"
README_SCRIPT="$ROOT_DIR/codex/README.md"
ROOT_README="$ROOT_DIR/README.md"

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

  mkdir -p "$fake_home/.codex/skills" "$fake_home/.agents/skills"
  touch "$fake_home/.codex/skills/old" "$fake_home/.agents/skills/old"

  HOME="$fake_home" \
  TIMESTAMP="20260313190001" \
  OWNED_SKILLS_ROOT="$own_root" \
  GENERATED_SKILLS_ROOT="$generated_root" \
  THIRD_PARTY_SKILLS_ROOT="$third_party_root" \
  bash "$INSTALL_SCRIPT"

  assert_eq "$(readlink "$fake_home/.codex/skills")" "$fake_home/.skills-installed" "codex skills link target"
  assert_eq "$(readlink "$fake_home/.agents/skills")" "$fake_home/.skills-installed" "agents skills link target"
  assert_eq "$(readlink "$fake_home/.skills-installed/alpha")" "$own_root/alpha" "owned skill target"
  assert_eq "$(readlink "$fake_home/.skills-installed/ed3d-omega")" "$generated_root/ed3d-omega" "generated skill target"
  assert_eq "$(readlink "$fake_home/.skills-installed/brainstorming")" "$third_party_root/brainstorming" "third-party skill target"

  test -e "$fake_home/.codex/skills.backup" || fail "expected codex backup"
  test -e "$fake_home/.agents/skills.backup" || fail "expected agents backup"

  local codex_backup_target
  local agents_backup_target
  codex_backup_target="$(readlink "$fake_home/.codex/skills.backup")"
  agents_backup_target="$(readlink "$fake_home/.agents/skills.backup")"

  HOME="$fake_home" \
  TIMESTAMP="20260313190002" \
  OWNED_SKILLS_ROOT="$own_root" \
  GENERATED_SKILLS_ROOT="$generated_root" \
  THIRD_PARTY_SKILLS_ROOT="$third_party_root" \
  bash "$INSTALL_SCRIPT"

  assert_eq "$(readlink "$fake_home/.codex/skills.backup")" "$codex_backup_target" "installer should not rotate codex backup when link is already correct"
  assert_eq "$(readlink "$fake_home/.agents/skills.backup")" "$agents_backup_target" "installer should not rotate agents backup when link is already correct"

  rm -rf "$sandbox"
}

run_docs_test() {
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.skills-installed"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/workspace/skills"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/.codex/superpowers"
  assert_file_contains "$README_SCRIPT" "/Users/liuwei/workspace/compat-ed3d"
  assert_file_contains "$README_SCRIPT" "skills-install.sh"
  assert_file_contains "$README_SCRIPT" "backup"
  assert_file_contains "$README_SCRIPT" "add a new source"
  assert_file_contains "$ROOT_README" "codex/README.md"
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
