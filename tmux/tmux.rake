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

  desc 'Reload tmux configuration for all sessions'
  task :reload do
    sessions = `tmux list-sessions -F '\#{session_name}'`.split("\n")
    config_path = home('.config/tmux/tmux.conf')

    sessions.each do |session|
      puts "Reloading config for session: #{session}"
      sh "tmux source-file -t #{session} #{config_path}"
    end

    puts "Reloaded tmux configuration for #{sessions.count} session(s)"
  end
end

task all: [:tmux]
task clean: ['tmux:clean']
