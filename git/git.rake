desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:dir, :setup_gh]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/git'), root('git'))
  end

  task :setup_gh do
    if which('gh')
      puts 'Installing gh extensions'
      sh 'gh extension install gennaro-tedesco/gh-f'
      puts 'Setting up gh aliases'
      sh 'gh alias set prs "f -p"'
      sh 'gh alias set l "f -l"'
    end
  end

  task :clean do
    sh "rm -f #{home('.config/git')}"
    sh "rm -rf #{home('.local/state/git')}"
  end

  desc 'Update all the git submodules in this repository'
  task :update do
    if which('gh')
      puts 'Updating gh extensions'
      sh 'gh extension upgrade --all'
    end
    puts 'Update: git submodules'.green
    puts 'Just kidding. There are no submodules in this repo.'
  end
end

task all: [:git]
task clean: ['git:clean']
# task update: ['git:update']
