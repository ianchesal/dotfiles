desc 'Install tmux dotfiles'
task tmux: ['tmux:conf']

namespace :tmux do
  task :conf do
    dolink(home('.tmux.conf'), root('tmux', 'tmux.conf'))
  end

  task :clean do
    clean_restore home('.tmux.conf')
  end
end

task all: [:tmux]
task clean: ['tmux:clean']
