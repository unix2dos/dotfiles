#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
zshrc="${repo_root}/zsh/.zshrc"
tmpdir=$(mktemp -d)
trap 'command rm -rf "$tmpdir"' EXIT

sgpt_args_file="${tmpdir}/sgpt.args"
sgpt_stdin_file="${tmpdir}/sgpt.stdin"
curl_args_file="${tmpdir}/curl.args"

mkdir -p "${tmpdir}/bin"
cat > "${tmpdir}/bin/curl" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$CURL_ARGS_FILE"
printf '%s\n' '{"choices":[{"message":{"content":"chore(test): direct commit"}}]}'
STUB
chmod +x "${tmpdir}/bin/curl"

cat > "${tmpdir}/bin/sgpt" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$SGPT_ARGS_FILE"
cat > "$SGPT_STDIN_FILE"
exit 99
STUB
chmod +x "${tmpdir}/bin/sgpt"

export PATH="${tmpdir}/bin:${PATH}"
export CURL_ARGS_FILE="$curl_args_file"
export SGPT_ARGS_FILE="$sgpt_args_file"
export SGPT_STDIN_FILE="$sgpt_stdin_file"
export AC_AI_API_BASE_URL="https://example.test/v1"
export AC_AI_API_KEY="test-key"
export AC_AI_MODEL="mimo-v2-pro"

source <(awk '
  /^# --- 8[.]2/ { in_section = 1 }
  /^# --- 8[.]3/ { exit }
  in_section { print }
' "$zshrc")

output=$(gitmsg ai <<< "diff --git a/file b/file")

[[ "$output" == "chore(test): direct commit" ]]
grep -q -- "https://example.test/v1/chat/completions" "$curl_args_file"
grep -q -- "Authorization: Bearer test-key" "$curl_args_file"
grep -q -- "mimo-v2-pro" "$curl_args_file"
[[ ! -s "$sgpt_args_file" ]]
