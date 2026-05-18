# Git aliases and helpers.

alias gs='git status'                          # Git 状态
alias gd='git diff'                            # Git diff
alias gdh='git diff HEAD'                      # Git diff HEAD
alias gt="git tag -ln9999 --sort=-version:refname"  # 显示所有 Git 标签
alias gwl='git worktree list'
alias ac="cz"                                  # AI commit helper

function _ac_now_ms() {
    zmodload zsh/datetime 2>/dev/null || {
        date +%s000
        return
    }
    printf '%.0f\n' "$(( EPOCHREALTIME * 1000 ))"
}

function _ac_trace() {
    [[ -n "${AC_AI_TRACE:-}" ]] || return 0
    local label="$1"
    local start_ms="$2"
    local now_ms=$(_ac_now_ms)
    echo "ac ai trace: ${label} $(( now_ms - start_ms ))ms" >&2
}

function _ac_sgpt_config_value() {
    local key="$1"
    local config="${SHELL_GPT_CONFIG_PATH:-$HOME/.config/shell_gpt/.sgptrc}"
    [[ -r "$config" ]] || return 1
    awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$config"
}

function _ac_extract_commit_message() {
    awk '
        /^[[:space:]]*```/ { next }
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)
            if (line ~ /^(feat|fix|refactor|style|docs|perf|ci|chore|test|build)(\([^)]+\))?!?: /) {
                print line
                found = 1
                exit
            }
            if (!first && length(line) > 0) {
                first = line
            }
        }
        END {
            if (!found && first) {
                print first
            } else if (!found) {
                exit 1
            }
        }
    '
}

function _ac_gitmsg_sgpt() {
    local lang_desc="$1"
    local model="${AC_AI_MODEL:-minimax-m2.5}"
    sgpt --model "$model" --no-md "Generate exactly one Conventional Commit message in ${lang_desc} from the git diff on stdin. Format: <type>(<scope>): <subject>. Use feat, fix, refactor, style, docs, perf, ci, or chore. Describe only the meaningful change. Output only the commit message, no explanation."
}

function _ac_gitmsg_direct() {
    local lang_desc="$1"
    local diff_content="$2"
    local model="${AC_AI_MODEL:-mimo-v2-pro}"
    local api_base="${AC_AI_API_BASE_URL:-$(_ac_sgpt_config_value API_BASE_URL)}"
    local api_key="${AC_AI_API_KEY:-$(_ac_sgpt_config_value OPENAI_API_KEY)}"
    local timeout="${AC_AI_TIMEOUT:-35}"

    [[ -n "$api_base" && -n "$api_key" ]] || return 1
    command -v curl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1

    local content="Git diff:
${diff_content}

Return exactly one Conventional Commit message in ${lang_desc} and nothing else. Use <type>(<scope>): <subject>."
    local payload response
    payload=$(jq -n --arg model "$model" --arg content "$content" \
        '{model:$model,messages:[{role:"user",content:$content}],temperature:0,stream:false}') || return 1

    response=$(curl --silent --show-error --fail --max-time "$timeout" \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "${api_base%/}/chat/completions") || return 1

    printf '%s' "$response" |
        jq -r '.choices[0].message.content // .choices[0].text // empty' |
        _ac_extract_commit_message
}

function gitmsg() {
    local lang_desc="中文"
    if [[ "$1" == "ai" ]]; then
        lang_desc="English"
    fi
    local diff_content
    diff_content=$(cat)

    if [[ "${AC_AI_BACKEND:-direct}" == "sgpt" ]]; then
        _ac_gitmsg_sgpt "$lang_desc" <<< "$diff_content"
        return
    fi

    _ac_gitmsg_direct "$lang_desc" "$diff_content" ||
        _ac_gitmsg_sgpt "$lang_desc" <<< "$diff_content"
}

# Analyze git diff HEAD, generate a commit message, then confirm/edit/commit.
function cz() {
    local diff_file=""
    local prompt_file=""
    {
        local diff_start=$(_ac_now_ms)
        diff_file=$(mktemp "${TMPDIR:-/tmp}/ac-ai-diff.XXXXXX") || return 1
        git diff --no-ext-diff --no-color HEAD >| "$diff_file"
        _ac_trace "git diff" "$diff_start"

        if [ ! -s "$diff_file" ]; then
            echo "Error: No changes to commit." >&2
            return 1
        fi

        local prepare_start=$(_ac_now_ms)
        local line_count=$(wc -l < "$diff_file" | tr -d ' ')
        local max_lines="${AC_AI_MAX_DIFF_LINES:-800}"
        [[ "$max_lines" == <-> ]] || max_lines=800
        prompt_file="$diff_file"

        if [ "$line_count" -gt 1200 ]; then
            echo "⚠️  Diff 较长（${line_count} 行），已截取前 ${max_lines} 行 + 文件统计" >&2
            prompt_file=$(mktemp "${TMPDIR:-/tmp}/ac-ai-prompt.XXXXXX") || return 1
            head -n "$max_lines" "$diff_file" >| "$prompt_file"
            {
                echo
                echo "... [Diff 过长已截断：共 ${line_count} 行，完整统计如下]"
                echo
                git diff --stat --no-ext-diff --no-color HEAD
            } >> "$prompt_file"
        fi
        _ac_trace "prepare diff (${line_count} lines)" "$prepare_start"

        local ai_start=$(_ac_now_ms)
        local message=$(gitmsg "$1" < "$prompt_file")
        _ac_trace "ai backend=${AC_AI_BACKEND:-direct} model=${AC_AI_MODEL:-mimo-v2-pro}" "$ai_start"

        if [ -z "$message" ]; then
            echo "Error: Failed to generate commit message." >&2
            return 1
        fi

        echo "Generated commit message:"
        echo "  $message"
        echo

        echo -n "Use git diff HEAD, Do you want to use this commit message? [Y/n/e] "

        if [ -n "$ZSH_VERSION" ]; then
            read -k 1 choice < /dev/tty
        else
            read -n 1 choice < /dev/tty
        fi
        echo

        case "$choice" in
            [nN])
                echo "Commit cancelled."
                return 1
                ;;
            [eE])
                local temp_file=$(mktemp)
                echo "$message" > "$temp_file"
                ${EDITOR:-vi} "$temp_file"
                message=$(cat "$temp_file")
                command rm -f "$temp_file"

                if [ -z "$message" ]; then
                    echo "Error: Empty commit message after editing." >&2
                    return 1
                fi
                ;;
            *)
                ;;
        esac

        git commit -m "$message"
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "✓ Commit successful!"
        else
            echo "✗ Commit failed with exit code: $exit_code" >&2
            return $exit_code
        fi
    } always {
        [[ -n "$diff_file" ]] && command rm -f "$diff_file"
        [[ -n "$prompt_file" && "$prompt_file" != "$diff_file" ]] && command rm -f "$prompt_file"
    }
}

# Generate multiple Chinese commit-message options.
function slg() {
    sgpt "为我的更改生成git提交消息，使用git提交最佳实践，不要添加前言和解释，直接输出提交内容，每条前面加一个序号, 并用中文输出"
}

# Generate an AI tag message and create a git tag.
function tag() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "输入version"
        return 1
    fi
    local message=$(slg)
    if [ -z "$message" ]; then
        echo "Warning: No message generated. Using empty message."
    fi
    git tag "$version" -m "$message"
    echo "Created git tag $version with message: \"$message\""
}
