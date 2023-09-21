desc 'Install tmux dotfiles'
task tmux: ['tmux:dir', 'tmux:plugins']

namespace :tmux do
  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/tmux'), root('tmux'))
  end

  task :plugins do
    puts 'Cloning tmp to ~/.tmux/plugins/tmp...'
    mkdir_if_needed home('.tmux/plugins')
    `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`
  end

  task :clean do
    sh "rm -f #{home('.config/tmux')}"
    sh "rm -rf #{home('.local/share/tmux')}"
    sh "rm -rf #{home('.local/state/tmux')}"
    sh "rm -rf #{home('.cache/tmux')}"
  end

  task :testterminal do
    sh 'bash ./tmux/24-bit-color.sh'
  end
end

task all: [:tmux]
task clean: ['tmux:clean']
