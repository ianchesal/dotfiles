desc 'Install ctags dotfiles'
task ctags: ['ctags:rc']

namespace :ctags do
  task :rc do
    dolink(home('.ctags'), root('ctags', 'ctags'))
  end

  task :clean do
    clean_restore home('.ctags')
  end
end
