#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
zshrc="${repo_root}/zsh/.zshrc"
tmpdir=$(mktemp -d)
trap 'command rm -rf "$tmpdir"' EXIT

sgpt_args_file="${tmpdir}/sgpt.args"
sgpt_stdin_file="${tmpdir}/sgpt.stdin"

mkdir -p "${tmpdir}/bin"
cat > "${tmpdir}/bin/sgpt" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$SGPT_ARGS_FILE"
cat > "$SGPT_STDIN_FILE"
printf '%s\n' 'chore(test): stub commit'
STUB
chmod +x "${tmpdir}/bin/sgpt"

export PATH="${tmpdir}/bin:${PATH}"
export SGPT_ARGS_FILE="$sgpt_args_file"
export SGPT_STDIN_FILE="$sgpt_stdin_file"
export AC_AI_MODEL="deepseek-v4-flash"

source <(awk '
  /^function gitmsg\(\)/ { in_function = 1 }
  in_function { print }
  in_function && /^}/ { exit }
' "$zshrc")

output=$(gitmsg ai <<< "diff --git a/file b/file")

[[ "$output" == "chore(test): stub commit" ]]
grep -qx -- "--model" "$sgpt_args_file"
grep -qx -- "deepseek-v4-flash" "$sgpt_args_file"
grep -qx -- "--no-md" "$sgpt_args_file"
grep -qx -- "diff --git a/file b/file" "$sgpt_stdin_file"

