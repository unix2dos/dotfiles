" 全局配置
let g:mapleader=";"   "注释, 默认leader 为 \ 
map <Space> <Leader>
" Tab键用来切换到下一个buffer
nnoremap <silent>   <tab> :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR> "切换buffer
nnoremap <silent> <s-tab> :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR> "切换buffer
nnoremap <leader>x :b#<bar>bd#<CR>"删除buffer

	

" vim插件 :PlugInstall
call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox' "主题
Plug 'vim-airline/vim-airline' "状态栏
Plug 'vim-airline/vim-airline-themes'
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='simple' " https://github.com/vim-airline/vim-airline/wiki/Screenshots

" 多光标
"Plug 'mg979/vim-visual-multi', {'branch': 'master'}
" 正则光标
Plug 'RRethy/vim-illuminate'



" vim里极速搜索文件开始 "
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" 大写 W 当前文件搜索文字, 依赖 fzf 模糊搜索
nnoremap W :BLines<CR>
" 使fzf默认使用ripgrep来查找文件
"if executable('rg') 
"    let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
"endif
" leader + r 搜索当前目录文字, 依赖 rg
nnoremap <Leader>r :RG<CR>
" leader + f 搜索当前目录文件, 依赖 FZF_DEFAULT_COMMAND
nnoremap <Leader>f :Files<CR>
" vim里极速搜索文件结束 "



" 极速搜索跳转插件开始 "
Plug 'easymotion/vim-easymotion' 
let g:EasyMotion_do_mapping = 0 " 禁用默认映射
let g:EasyMotion_smartcase = 1 " 启用智能大小写
" 全局搜索替代 / 和 ?
map / <Plug>(easymotion-sn)
map ? <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
omap ? <Plug>(easymotion-tn)
" n/N 命令
map n <Plug>(easymotion-next)
map N <Plug>(easymotion-prev)
" 行跳转
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
" 单词跳转
" 一个大写F 屌爆天
nmap F <Plug>(easymotion-bd-w)
map <Leader>w <Plug>(easymotion-w)
map <Leader>b <Plug>(easymotion-b)
map <Leader>e <Plug>(easymotion-e)
" 极速搜索跳转插件结束 "




call plug#end()

" 注释掉的插件
"Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
"Plug 'majutsushi/tagbar' "tagbar
"Plug 'scrooloose/nerdtree' "导航树
"Plug 'jistr/vim-nerdtree-tabs' "导航树插件
"Plug 'ervandew/supertab' "supertab
"Plug 'SirVer/ultisnips' "代码模板
"Plug 'Valloric/YouCompleteMe' "table补全
"Plug 'Shougo/neocomplete.vim' "代码实时提示


" vim 配置
filetype off                    " 首先重置文件类型检测
filetype plugin indent on       " 启用文件类型检测
set number                      " 显示行号
set backspace=indent,eol,start  " 使退格键更强大，可以删除缩进、行尾和行首
set tabstop=4                   " 设定tab长度为4
set shiftwidth=4                " 缩进的空格数为4
set mouse-=a                    " 可以用鼠标拖动
set clipboard=unnamed           " 鼠标选中y复制到系统剪贴板
set nocompatible                " 启用Vim特有功能，不兼容Vi
set ttyfast                     " 指示快速终端连接以加快显示
set ttymouse=xterm2             " 指定终端类型以支持鼠标代码
set ttyscroll=3                 " 加速滚动
set laststatus=2                " 总是显示状态栏
set encoding=utf-8              " 设置默认编码为UTF-8
set autoread                    " 自动读取已更改的文件
set autoindent                  " 启用自动缩进
set incsearch                   " 输入搜索内容时就显示搜索结果
set noerrorbells                " 关闭错误提示音
set showcmd                     " 显示正在输入的命令
set noswapfile                  " 不使用交换文件
set nobackup                    " 不创建备份文件
set splitright                  " 垂直分割窗口时，新窗口在右边
set splitbelow                  " 水平分割窗口时，新窗口在下方
set autowrite                   " 在执行:next、:make等命令前自动保存
set hidden                      " 关闭窗口时缓冲区仍然存在
set fileformats=unix,dos,mac    " 文件格式首选顺序：Unix、Windows、Mac
set noshowmatch                 " 不通过闪烁显示匹配的括号
set noshowmode                  " 不显示当前模式（通常由airline或lightline插件显示）
set ignorecase                  " 搜索时忽略大小写
set smartcase                   " 但如果搜索内容包含大写字母则区分大小写
set completeopt=menu,menuone    " 显示补全菜单，即使只有一个选项
set pumheight=10                " 补全窗口最大高度
set nocursorcolumn              " 不高亮显示当前列
set nocursorline                " 不高亮显示当前行
set lazyredraw                  " 延迟重绘以提高性能

