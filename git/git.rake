desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/git'), root('git'))
  end

  task :clean do
    sh "rm -f #{home('.config/git')}"
    sh "rm -rf #{home('.local/state/git')}"
  end

  desc 'Update all the git submodules in this repository'
  task :update do
    puts 'Update: git submodules'.green
    puts 'Just kidding. There are no submodules in this repo.'
  end
end

task all: [:git]
task clean: ['git:clean']
# task update: ['git:update']
