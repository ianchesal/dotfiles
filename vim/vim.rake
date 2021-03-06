desc 'Install vim and neovim dotfiles'
task vim: ['vim:all']

namespace :vim do
  task all: [:dir, :rc]

  task :rc do
    dolink(home('.vimrc'), root('vim', 'vimrc'))
    dolink(home('.config/nvim/init.vim'), root('vim', 'vimrc'))
    Dir.glob('vim/ftplugin/*.vim') do |pfile|
      pfile = File.basename(pfile)
      dolink(home(".vim/ftplugin/#{pfile}"), root('vim', 'ftplugin', pfile))
    end
  end

  task :dir do
    mkdir_if_needed home('.config')
    mkdir_if_needed home('.vim')
    mkdir_if_needed home('.vim/ftplugin')
    dolink('~/.config/nvim', '~/.vim')
  end

  desc 'Update vim plugins'
  task :update do
    puts 'Update: vim-plug plugins'.green
    sh 'vim +PlugUpgrade +qall'
    sh 'vim +PlugInstall +qall'
    sh 'vim +PlugUpdate +qall'
  end

  task :clean do
    sh "rm -rf #{home('.vim')}/*"
    clean_restore home('.vimrc')
  end
end

task all: [:vim]
task clean: ['vim:clean']
task update: ['vim:update']
