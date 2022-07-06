desc 'Install tmux dotfiles'
task tmux: ['tmux:conf', 'tmux:plugins']

namespace :tmux do
  task :conf do
    dolink(home('.tmux.conf'), root('tmux', 'tmux.conf'))
  end

  task :plugins do
    puts "Cloning tmp to ~/.tmux/plugins/tmp..."
    mkdir_if_needed home('.tmux/plugins')
    `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
  end

  task :clean do
    clean_restore home('.tmux.conf')
  end
end

task all: [:tmux]
task clean: ['tmux:clean']
