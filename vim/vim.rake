desc 'Install vim and neovim dotfiles'
task vim: ['vim:all']

namespace :vim do
  task all: [:dir, :rc]

  task :rc do
    dolink(home('.vimrc'), root('vim', 'vimrc'))
    dolink(home('.config/nvim/init.vim'), root('vim', 'vimrc'))
    Dir.glob('vim/lua/*.lua') do |pfile|
      pfile = File.basename(pfile)
      dolink(home(".vim/lua/#{pfile}"), root('vim', 'lua', pfile))
    end
    Dir.glob('vim/ftplugin/*.vim') do |pfile|
      pfile = File.basename(pfile)
      dolink(home(".vim/ftplugin/#{pfile}"), root('vim', 'ftplugin', pfile))
    end
  end

  task :dir do
    mkdir_if_needed home('.config')
    mkdir_if_needed home('.vim')
    mkdir_if_needed home('.vim/ftplugin')
    mkdir_if_needed home('.vim/lua')
    dolink('~/.config/nvim', '~/.vim')
    sh 'rm -f ~/.vim/.vim' # I have no idea why this keeps getting created
  end

  desc 'Update vim plugins'
  task :update do
    puts 'Update: vim-plug plugins'.green
    sh 'nvim +PlugUpgrade +qall'
    sh 'nvim +PlugInstall +qall'
    sh 'nvim +PlugUpdate +qall'
  end

  task :clean do
    sh "rm -rf #{home('.config/nvim')}"
    sh "rm -rf #{home('.local/share/nvim')}"
    sh "rm -rf #{home('.vim')}/*"
    clean_restore home('.vimrc')
  end
end

# task all: [:vim]
# task clean: ['vim:clean']
# task update: ['vim:update']
