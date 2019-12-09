desc 'Install vim and neovim dotfiles'
task vim: ['vim:all']
task :vim do
  puts "Now run:\n\n"
  puts "\tbrew uninstall vim; rvm system; brew install vim"
  puts "\tvim +PluginInstall +qall"
  puts "\tcd ~/.vim/bundle/YouCompleteMe; ./install.sh"
  puts "\nto complete the installation."
end

namespace :vim do
  task all: [:dir, :rc]

  task :rc do
    dolink(home('.vimrc'), root('vim', 'vimrc'))
    dolink(home('.config/nvim/init.vim'), root('vim', 'vimrc'))
  end

  task :dir do
    mkdir_if_needed home('.config')
    mkdir_if_needed home('.vim')
    dolink('~/.config/nvim', '~/.vim')
  end

  task :clean do
    system "rm -rf #{home('.vim')}/*"
    clean_restore home('.vimrc')
  end
end

task all: [:vim]
task clean: ['vim:clean']
