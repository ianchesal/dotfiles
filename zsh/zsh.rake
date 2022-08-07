require 'pathname'

desc 'Install zsh dotfiles'
task zsh: ['zsh:dotzsh', 'zsh:rc']

namespace :zsh do
  task :dotzsh do
    puts "Creating symlink ~/.zsh..."
    dolink(home('.zsh'), root('zsh'))
  end

  task :rc do
    dolink(home('.zshenv'), root('zsh', '.zshenv'))
  end

  desc 'Update zsh and antidote'
  task :update do
    puts 'Update: antidote'.green
    sh 'zsh -i -c \'antidote update && exit\''
  end

  task :clean do
    clean_restore home('.zshenv')
    clean_restore home('.zsh')
  end
end

task all: [:zsh]
task clean: ['zsh:clean']
task update: ['zsh:update']
