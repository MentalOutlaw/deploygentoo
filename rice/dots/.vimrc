let mapleader =","
filetype off

set bg=light
set go=a
set mouse=a
set nohlsearch
set clipboard=unnamedplus
"Sets tab size to 4 spaces
set tabstop=4
set softtabstop=4
set shiftwidth=4
"Convertts our tabs to spaces
set expandtab
set autoindent
set fileformat=unix

if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'mattn/emmet-vim'
call plug#end()


" Some basics:
	nnoremap c "_c
	set nocompatible
	"filetype plugin on
	syntax on
	set encoding=utf-8
	set number relativenumber
" Enable autocompletion:
	"set wildmode=longest,list,full
" Disables automatic commenting on newline:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
	set splitbelow splitright

" Shortcutting split navigation, saving a keypress:
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l
" Emmet Shortcuts
let g:user_emmet_mode='n'   "Only enable normal mode functions.
let g:user_emmet_leader_key=','

" Replace all is aliased to S.
	nnoremap S :%s//g<Left><Left>

" Copy selected text to system clipboard (requires gvim/nvim/vim-x11 installed):
	vnoremap <C-c> "+y
	map <C-p> "+P
"Newtab with ctrl+t
	nnoremap <silent> <C-t> :tabnew<CR>
"Paste from system clipboard with ctrl+i instead of shift insert
	map <S-Insert> <C-i>

"Automatically deletes all trailing whitespace on save.
       autocmd BufWritePre * %s/\s\+$//e

"When shortcut files are updated, renew bash and vifm configs with new material:
       autocmd BufWritePost ~/.config/bmdirs,~/.config/bmfiles !shortcuts

"Update binds when sxhkdrc is updated.
       autocmd BufWritePost *sxhkdrc !pkill -USR1 sxhkd

"Run xrdb whenever Xdefaults or Xresources are updated.
       autocmd BufWritePost *Xresources,*Xdefaults !xrdb %

"Navigating with guides
	inoremap <leader><leader> <Esc>/<++><Enter>"_c4l
	vnoremap <leader><leader> <Esc>/<++><Enter>"_c4l
	map <leader><leader> <Esc>/<++><Enter>"_c4l
