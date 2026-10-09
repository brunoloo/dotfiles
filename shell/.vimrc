set number
set cursorline
set showcmd
set wildmenu
set hidden
set ttyfast
set backspace=indent,eol,start

set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4

" to copy on select and paste on rclick
set mouse=

set redrawtime=10000
autocmd VimResized * redraw!


" bindings

" Alt+Up/Down to move current line up/down
nnoremap <A-Up>   :m .-2<CR>==
nnoremap <A-Down> :m .+1<CR>==
inoremap <A-Up>   <Esc>:m .-2<CR>==gi
inoremap <A-Down> <Esc>:m .+1<CR>==gi
vnoremap <A-Up>   :m '<-2<CR>gv=gv
vnoremap <A-Down> :m '>+1<CR>gv=gv
