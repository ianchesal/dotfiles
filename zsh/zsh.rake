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
    puts 'Updating zinit'.green
    puts 'TODO: Figure this out'
    # sh 'zinit self-update'
    # sh 'zinit update'
  end

  task :clean do
    clean_restore home('.zshenv')
    FileUtils.rm_f home('.config/zsh')
    FileUtils.rm_f home('.local/share/zsh')
    FileUtils.rm_rf('zsh/plugins')
  end
end

task all: [:zsh]
task clean: ['zsh:clean']
# task update: ['zsh:update']
