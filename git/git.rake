desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:gitconfig, :gitignore, :gittemplate]

  task :gitconfig do
    dolink(home('.gitconfig'), root('git', 'gitconfig.common'))
  end

  task :gitignore do
    dolink(home('.gitignore'), root('git', 'gitignore'))
  end

  task :gittemplate do
    mkdir_if_needed home('.git_template')
  end

  task :gitlocalpersonal do
    dolink(home('.gitlocal'), root('git', 'gitlocal.personal'))
  end

  desc 'Update all the git submodules in this repository'
  task :update do
    puts 'Update: git submodules'.green
    sh 'git pull --recurse-submodules'
  end

  task :clean do
    clean_restore home('.gitignore')
    clean_restore home('.gitconfig')
  end
end

task all: [:git]
task clean: ['git:clean']
#task update: ['git:update']
