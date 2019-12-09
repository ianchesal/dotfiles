desc 'Install emacs dotfiles'
task emacs: ['emacs:all']

namespace :emacs do
  task :all do
    dolink(home('.spacemacs'), root('emacs', 'spacemacs'))
  end

  task :clean do
    clean_restore home('.spacemacs')
  end
end

task all: [:emacs]
task clean: ['emacs:clean']
