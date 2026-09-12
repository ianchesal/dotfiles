# frozen_string_literal: true

# The tmux CONFIG now lives in home/dot_config/tmux/ and is deployed by chezmoi.
# What survives here are the two utility tasks that have no chezmoi equivalent.

namespace :tmux do
  desc 'Reload tmux configuration for all sessions'
  task :reload do
    sessions = `tmux list-sessions -F '\#{session_name}'`.split("\n")
    config_path = home('.config/tmux/tmux.conf')

    sessions.each do |session|
      puts "Reloading config for session: #{session.inspect}"
      # Array form: session names may contain spaces, so never build a shell string
      sh 'tmux', 'source-file', '-t', session, config_path
    end

    puts "Reloaded tmux configuration for #{sessions.count} session(s)"
  end

  desc 'Print a 24-bit colour test pattern in this terminal'
  task :testterminal do
    sh 'bash', home('.config/tmux/24-bit-color.sh')
  end
end
