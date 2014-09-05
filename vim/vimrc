call pathogen#runtime_append_all_bundles()

""""""""""""""""""""""
" Basic configuration
"
set nocp          " Disable vi compatibility, for vim-specific awesomeness
set expandtab     " Expand tabs to spaces
set tabstop=2
set bs=2          " Fix backspace key to work under screen
set shiftwidth=2
set number        " Enable line numbering
set autoindent    " When you press enter you stay at the current indent
set wildmode=longest,list " Better tab completion for :e and friends
set wildignore=*.rbc,.git,*.o,*.gem
set history=100   " Default is 20, not enough.
set ls=2          " Always display a status line
set colorcolumn=80 " Vertical bar at 80 chars

set visualbell     " Use visual bell instead of beeping.
set shortmess=atI  " short info tokens, short command line messages, no intro.
set modelines=0    " Disable modelines; not used, risk of security exploits.
set encoding=utf-8 " Default to Unicode/UTF-8 rather than latin1
set ttyfast        " Terminals are plenty fast these days.

set winwidth=81    " Ideal minimum window width of 80 chars

set gfn=Monofur:h14

syntax on

filetype plugin indent on

" Mouse is useful for scrolling and selection in some cases
if has("mouse")
	set mouse=a
	set mousehide
endif

" Store temporary files in a central spot
set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

" Use ack for grepping
set grepprg=ack
set grepformat=%f:%l:%m

" These leaders work better with Colemak
let mapleader = ";"
let maplocalleader = ","


""""""""""""""""
" PRETTY COLORS
"
if has("gui_running")
  set guioptions=egmrt
endif

set t_Co=256

set background=dark
colorscheme solarized

call togglebg#map("<F3>")


"""""""""""""""""""""""
" GENERIC KEY BINDINGS
"

" Disable help key coz I mash it when I try to hit Esc
map <F1> <Esc>
imap <F1> <Esc>

" Expands to directory of current file
cnoremap %% <C-R>=expand('%:h').'/'<cr>

" Bind tab to shift between buffers
nmap <tab> :bn<cr>
nmap <s-tab> :bp<cr>

function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
map <leader>n :call RenameFile()<cr>

" Strip trailing whitespace
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>

" Unbind the cursor keys in insert, normal and visual modes.
for prefix in ['i', 'n', 'v']
  for key in ['<Up>', '<Down>', '<Left>', '<Right>']
    exe prefix . "noremap " . key . " <Nop>"
  endfor
endfor


"""""""
" TMUX
"

" Requires tslime.vim
map <leader>s :w\|:call Send_to_Tmux("!!\n")<CR>


"""""""
" RUBY
"

vmap <F2> !format_hash.rb<CR>
vmap <F4> !format_cucumber_table.rb<CR>

" Comment/uncomment ruby code
vmap o :s/^/# /<CR>
vmap i :s/^# //<CR>

" Convert old style ruby hashes to new style
vmap ;h :s/:\(\w*\)\s*=> /\1: /g<CR>

" Rails specific
map <leader>gr :topleft :split config/routes.rb<cr>
map <leader>gg :topleft 100 :split Gemfile<cr>

function! PromoteToLet()
  :normal! dd
  " :exec '?^\s*it\>'
  :normal! P
  :.s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
  :normal ==
endfunction
:command! PromoteToLet :call PromoteToLet()
:map <leader>p :PromoteToLet<cr>


""""""""""
" CLOJURE
"
let vimfiles=$HOME . "/.vim"
let sep=":"
let vimclojureRoot = vimfiles."/bundle/vimclojure-2.2.0"
let vimclojure#ParenRainbow = 1
let vimclojure#WantNailgun = 0
let classpath = join( [".", "src", "src/main/clojure", "src/main/resources", "test", "src/test/clojure", "src/test/resources", "classes", "target/classes", "lib/*", "lib/dev/*", "bin", vimfiles."/lib/*" ], sep)

"""""""""""
" LILYPOND
"

set runtimepath+=/Applications/LilyPond.app/Contents/Resources/share/lilypond/current/vim

"""""""""""""""""""""""""""""
" HIGHLIGHTING AND FILE TYPES
"

" Highlight trailing whitespace etc
highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
match ExtraWhitespace /\s\+\%#\@<!$/

augroup vimrcEx
  autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red

  "Auto reload this file when editing it
  au! BufWritePost .vimrc source %

  "Add rails filetype to all ruby files, need to find a way to limit to just rails files maybe
  au BufRead,BufNewFile *.rb set filetype=ruby.rails.rspec
  au BufRead,BufNewFile Isolate set filetype=ruby
  au BufRead,BufNewFile config.ru set filetype=ruby

  " Override default modula2 detection, these files are markdown
  au BufNewFile,BufRead *.md set filetype=markdown

  " C style for ruby codes
  au FileType c setl ts=4 sw=4 noexpandtab

  " Exit insert mode when Vim loses focus.
  " A bug prevents this from working: autocmd FocusLost * stopinsert
  " See http://stackoverflow.com/questions/2968548
  autocmd! FocusLost * call feedkeys("\<C-\>\<C-n>")

  " Jump to last cursor position unless it's invalid or in an event handler
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

augroup END
