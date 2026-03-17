# ============================================
# ZSH 配置文件
# ============================================
# 作者: liuwei
# 说明: Zsh shell 环境配置，包含键绑定、历史记录、插件、
#       环境变量、路径配置、别名和函数定义等
# ============================================


# ============================================
# 1. ZSH 基础设置
# ============================================

# --- 1.1 键盘绑定 ---
bindkey \^U backward-kill-line  # Ctrl+U 从光标位置向左删除到行首
bindkey -e                      # 切换为 Emacs 编辑模式
setopt IGNORE_EOF               # 防止使用 Ctrl+D 意外退出 shell

# --- 1.2 混合删除模式配置 ---
# 精细删除模式：设定单词分隔符（从默认列表里删除了 / . -）
# Ctrl+W 会自动使用这个规则，让删除更精确
export WORDCHARS='*?_[]~=&;!#$%^(){}<>'

# 暴力删除函数：临时把 / . - 加回去，当作一体删除
my-aggressive-backward-kill-word() {
    local WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
    zle backward-kill-word
}
zle -N my-aggressive-backward-kill-word

# 绑定快捷键 Option + Delete (macOS/Ghostty 中发送 Escape + Backspace)
bindkey '^[^?' my-aggressive-backward-kill-word


# ============================================
# 2. 历史记录配置
# ============================================

HISTFILE="$HOME/.zsh_history"  # 历史记录文件路径
HISTSIZE=50000                 # 内存中保存的历史记录条数
SAVEHIST=50000                 # 文件中保存的历史记录条数

# --- 历史记录行为 ---
setopt SHARE_HISTORY           # 多终端/tmux 窗格之间共享历史记录
setopt APPEND_HISTORY          # 追加而不是覆盖历史文件
setopt INC_APPEND_HISTORY      # 执行完命令后立即追加到历史文件
setopt EXTENDED_HISTORY        # 记录时间戳
setopt HIST_IGNORE_DUPS        # 忽略连续重复命令
setopt HIST_IGNORE_ALL_DUPS    # 忽略所有重复命令
setopt HIST_IGNORE_SPACE       # 忽略以空格开头的命令（防止敏感信息记录）


# ============================================
# 3. 环境变量
# ============================================

# --- 3.1 系统环境变量 ---
export TERM=xterm-256color     # 终端类型
export LC_ALL=en_US.UTF-8      # 语言和字符集
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export EDITOR='vim'            # 默认编辑器

# --- 3.2 开发环境变量 ---
export ENV="local"             # 环境标识
export ENVIRON="local"
export AUTOSSH_GATETIME=0      # AutoSSH 配置
export COMPOSE_BAKE=true       # Docker Compose 配置
export GIT_TERMINAL_PROMPT=1   # Git 允许用户名密码拉取

# --- 3.3 调试配置 ---
export SSLKEYLOGFILE="$HOME/Desktop/sslkeylog.log"  # SSL 密钥日志文件

# --- 3.4 Tmux 配置 ---
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
export TMUX_PLUGIN_MANAGER_DEBUG=1

# --- 3.5 Go 语言环境 ---
export GOPATH=$HOME/go
export GO111MODULE=on          # 启用 Go Modules
export CGO_ENABLED=1           # 启用 CGO
export GOPROXY=https://goproxy.cn,direct      # Go 代理
export GOPRIVATE="*.hoxigames.xyz"            # 私有仓库，不走代理
export GONOPROXY="*.hoxigames.xyz"
export GONOSUMDB="*.hoxigames.xyz"
export GOINSECURE="*.hoxigames.xyz"

# --- 3.6 Java 环境 ---
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_311.jdk/Contents/Home

# --- 3.7 Homebrew 配置 ---
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles


# ============================================
# 4. PATH 路径配置
# ============================================

# --- PATH 管理工具函数 ---
path_prepend() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *:"$1":*) ;;
            *) PATH="$1:$PATH" ;;
        esac
    fi
}

path_append() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *:"$1":*) ;;
            *) PATH="$PATH:$1" ;;
        esac
    fi
}

# --- 前置：需要覆盖系统同名命令 ---
path_prepend "$HOME/.local/bin"                                  # 本地二进制文件（最高优先级）
path_prepend "/opt/anaconda3/bin"                                # Anaconda
path_prepend "$HOME/anaconda3/bin"                               # Anaconda (用户目录)
path_prepend "$HOME/Library/Python/3.8/bin"                      # Python 3.8
path_prepend "$HOME/.cargo/bin"                                  # Rust Cargo
path_prepend "$JAVA_HOME/bin"                                    # Java

# --- 后置：独立命令，无冲突风险 ---
path_append "$GOPATH/bin"                                        # Go 二进制文件
path_append "/Applications/Alacritty.app/Contents/MacOS"         # Alacritty 终端
path_append "/opt/homebrew/opt/trash/bin"                        # Trash 垃圾桶工具
path_append "$HOME/.spicetify"                                   # Spicetify (Spotify 美化)
path_append "$HOME/.amp/bin"                                     # Amp CLI
path_append "$HOME/.opencode/bin"                                # Opencode
path_append "$HOME/.bun/bin"                                     # Bun

export PATH

# pnpm 路径配置（已自带去重）
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# ============================================
# 5. Zsh 插件管理 (Antidote)
# ============================================

# 插件列表
zsh_plugins=(
  # --- 核心补全 ---
  'zsh-users/zsh-completions'                  # Zsh 自带补全功能的扩展包

  # --- Oh My Zsh 小工具 ---
  'ohmyzsh/ohmyzsh path:plugins/z'             # 快速目录跳转
  'ohmyzsh/ohmyzsh path:plugins/copypath'      # 复制路径

  # --- 界面增强 ---
  'so-fancy/diff-so-fancy'                     # 更美观的 diff 输出
  'Aloxaf/fzf-tab'                             # 使用 fzf 进行 tab 补全

  # --- Git 增强 ---
  # 'wfxr/forgit'                              # 交互式 Git 工具 (需要 fzf)

  # --- 效率工具 ---
  'zsh-users/zsh-autosuggestions'              # 自动建议（灰色幽灵文字）
  'zsh-users/zsh-history-substring-search'     # 历史子字符串搜索

  # --- 语法高亮 (必须最后加载) ---
  'zsh-users/zsh-syntax-highlighting'          # 命令语法高亮
)

# Antidote 初始化
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# 插件配置文件路径
_antidote_plugins_txt=${ZDOTDIR:-~}/.zsh_plugins.txt
_antidote_static_file=${ZDOTDIR:-~}/.zsh_plugins.zsh

# 智能判断：如果插件列表改变，重新生成插件文件
if [[ ! -f $_antidote_plugins_txt ]] || \
   [[ $(cat $_antidote_plugins_txt) != $(printf "%s\n" "${zsh_plugins[@]}") ]]; then
  printf "%s\n" "${zsh_plugins[@]}" >| $_antidote_plugins_txt
  antidote bundle < $_antidote_plugins_txt >| $_antidote_static_file
fi

# 加载插件
source $_antidote_static_file

# 初始化补全系统（必须在插件加载完之后）
fpath+=(${ZDOTDIR:-~}/.zsh_functions)
autoload -U compinit && compinit


# ============================================
# 6. 插件配置
# ============================================

# --- Starship 提示符 ---
eval "$(starship init zsh)"

# --- fzf-tab 配置 ---
# 在 Tmux 中使用弹窗模式
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# --- history-substring-search 配置 ---
# 绑定上下箭头键进行历史搜索
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down


# ============================================
# 7. 命令别名
# ============================================

# --- 7.1 Git 别名 ---
alias gs='git status'                          # Git 状态
alias gd='git diff'                            # Git diff
alias gdh='git diff HEAD'                      # Git diff HEAD
alias gt="git tag -ln9999 --sort=-version:refname"  # 显示所有 Git 标签
alias gwl='git worktree list'

# --- 7.2 文件操作别名 ---
alias ls='eza -h'                              # 更好的 ls (使用 eza)
alias ll='eza -alh --total-size --icons'       # 详细列表显示
alias rm="trash"                               # 使用 trash 代替 rm
alias open="open -R"                           # 在 Finder 中显示

# --- 7.3 工具别名 ---
alias grep="rg"                                # 使用 ripgrep 代替 grep
alias t="tmux"                                 # Tmux 快捷方式
alias r="rustc"                                # Rust 编译器
alias ac="czg"                                 # Commitizen
alias c="cluade"

# --- 7.4 网络和代理 ---
alias ssh='AUTOSSH_GATETIME=0 autossh -M 0'    # 使用 AutoSSH
alias ssho='command ssh'                       # 原生 SSH
alias proxy='export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897'  # 开启代理
alias disproxy='unset http_proxy https_proxy all_proxy'  # 关闭代理
alias myip='curl ifconfig.co/json'             # 查看公网 IP

# --- 7.5 快捷路径 ---
alias lw="cd ~/go/src/picplus"                 # 快速进入项目目录


# ============================================
# 8. 自定义函数
# ============================================

# --- 8.1 搜索工具 ---
# 搜索文件名（使用 ripgrep）
function rgf {
	rg --files -uuu $2 | rg $1
}

# --- 8.2 AI Git 提交辅助函数 ---
function gitmsg() {
   local lang_desc="中文"
   if [[ "$1" == "ai" ]]; then
       lang_desc="English"
   fi
   sgpt "你是一位资深的软件工程师，擅长编写清晰、规范的 Git 提交信息。根据我提供的内容，生成一条符合「约定式提交规范」的${lang_desc} Git 提交信息。要求: 1.  格式: 严格遵循 \`<类型>(<范围>): <主题>\` 的格式。常用类型: \`feat\`(新功能), \`fix\`(修复), \`refactor\`(重构), \`style\`(格式), \`docs\`(文档), \`perf\`(性能), \`ci\`(持续集成), \`chore\`(杂务)。2.内容: 用言简意赅的${lang_desc}进行描述。只描述核心的、用户可感知或对开发者重要的变更。省略不重要的细节，如修改变量名、调整缩进等（除非是\`style\`类型的提交）。3. 输出:不要添加任何前言、解释或思考过程,直接输出最终的提交信息，且仅输出一条。"
}

alias ca='opencode -m opencode/minimax-m2.1-free run "提交全部代码"'
# --- 8.3 智能提交函数 (cz) ---
# 功能: 分析 git diff HEAD，生成提交消息，支持确认/编辑/取消
function cz() {
	local message=$(gitmsg "$1" <<< "$(git diff HEAD)")

    if [ -z "$message" ]; then
        echo "Error: Failed to generate commit message." >&2
        return 1
    fi

    echo "Generated commit message:"
    echo "  $message"
    echo

    # 询问用户是否确认使用该提交信息
    echo -n "Use git diff HEAD, Do you want to use this commit message? [Y/n/e] "

    # 兼容 bash 和 zsh 的读取方式
    if [ -n "$ZSH_VERSION" ]; then
		read -k 1 choice < /dev/tty
    else
	    read -n 1 choice < /dev/tty
    fi
    echo  # 换行

    case "$choice" in
        [nN])
            echo "Commit cancelled."
            return 1
            ;;
        [eE])
            # 允许用户编辑提交信息
            local temp_file=$(mktemp)
            echo "$message" > "$temp_file"
            ${EDITOR:-vi} "$temp_file"
            message=$(cat "$temp_file")
            rm -f "$temp_file"

            if [ -z "$message" ]; then
                echo "Error: Empty commit message after editing." >&2
                return 1
            fi
            ;;
        *)
            # 默认情况下（Y或直接回车）使用生成的信息
            ;;
    esac


    # 执行 git commit
    git commit -m "$message"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✓ Commit successful!"
    else
        echo "✗ Commit failed with exit code: $exit_code" >&2
        return $exit_code
    fi
}

# --- 8.4 智能 Git Tag 函数 ---
# 使用 AI 生成多条提交消息选项
function slg() {
	sgpt "为我的更改生成git提交消息，使用git提交最佳实践，不要添加前言和解释，直接输出提交内容，每条前面加一个序号, 并用中文输出"
}
# 使用 AI 生成 tag 消息并创建 tag
# 用法: tag v1.0.0
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


# ============================================
# 9. 第三方软件初始化
# ============================================

# --- 9.1 NVM (Node Version Manager) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"                      # 加载 nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"   # 加载 nvm 自动补全

# --- 9.2 Conda (Anaconda/Miniconda) ---
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# --- 9.3 FZF (Fuzzy Finder) ---
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF Tmux Popup 配置
if [[ -n $TMUX_PANE ]] && (( $+commands[tmux] )) && (( $+commands[fzfp] )); then
	export TMUX_POPUP_NESTED_FB='test $(tmux display -pF "#{==:#S,floating}") == 1'
	export TMUX_POPUP_WIDTH=80%
fi

# --- 9.4 Bun 自动补全 ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- 9.5 Kiro 终端集成 ---
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


# ============================================
# 10. 系统行为配置
# ============================================

# --- 自动进入 Tmux (SSH 连接) ---
# 如果是 SSH 连接且不在 Tmux 中，自动附加或创建 ssh_tmux 会话
if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
	  tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
fi


# ============================================
# 配置文件结束
# ============================================

# Auto Accept — launch Antigravity with CDP
alias antigravity-cdp='open -n -a "/Applications/Antigravity.app" --args --remote-debugging-port=9000'
