desc 'Install vim (yea, like the old school vim) dotfiles'
task vim: ['vim:all']

namespace :vim do
  task all: [:dir, :rc]

  task :rc do
    dolink(home('.vimrc'), root('vim', 'vimrc'))
  end

  task :dir do
    mkdir_if_needed home('.vim')
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

# These are not on by default
# task all: [:vim]
# task clean: ['vim:clean']
# task update: ['vim:update']
