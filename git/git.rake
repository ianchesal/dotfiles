desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:gitconfig, :gitignore, :gittemplate]

  task :gitconfig do
    dolink(home('.gitconfig'), root('git', 'gitconfig'))
  end

  task :gitignore do
    dolink(home('.gitignore'), root('git', 'gitignore'))
  end

  task :gittemplate do
    mkdir_if_needed home('.git_template')
  end

  task :clean do
    clean_restore home('.gitignore')
    clean_restore home('.gitconfig')
  end
end

task all: [:git]
task clean: ['git:clean']
