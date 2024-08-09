require 'pathname'

desc 'Install zsh dotfiles'
task zsh: ['zsh:dotzsh', 'zsh:rc']

namespace :zsh do
  task :dotzsh do
    puts 'Creating symlink ~/.config/zsh...'
    mkdir_if_needed home('.config')
    mkdir_if_needed home('.local/share/zsh')
    dolink(home('.config/zsh'), root('zsh'))
    mkdir_if_needed home('.cache')
    mkdir_if_needed home('.cache/completions')
  end

  task :rc do
    dolink(home('.zshenv'), root('zsh', '.zshenv'))
  end

  desc 'Update zsh and plugins'
  task :update do
    %w[powerlevel10k fast-syntax-highlighting zephyr zsh-vim-mode zsh-history-substring-search fzf-zsh-plugin fzf-tab fzf-tab-source].each do |plugin|
      puts "Update: #{plugin}".green
      sh "cd zsh/plugins/#{plugin} && git pull"
    end
    # puts 'Update: antidote'.green
    # FileUtils.rm_f home('.config/zsh/.zsh_plugins.zsh')
    # sh 'zsh -i -c \'antidote update; exit\''
    # sh 'rm -f ~/.config/zsh/.zcompdump*; compinit'
  end

  task :clean do
    clean_restore home('.zshenv')
    FileUtils.rm_f home('.config/zsh')
    FileUtils.rm_f home('.local/share/zsh')
  end
end

task all: [:zsh]
task clean: ['zsh:clean']
task update: ['zsh:update']
