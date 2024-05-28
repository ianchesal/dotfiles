desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:dir, :setup_gh]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/git'), root('git'))
    dolink(home('.config/gh'), root('git/gh'))
    dolink(home('.config/gh-dash'), root('git/gh-dash'))
  end

  task :setup_gh do
    if which('gh')
      puts 'Installing gh extensions'
      sh 'gh extension install gennaro-tedesco/gh-f'
      sh 'gh extension install dlvhdr/gh-dash'
      # These are in gh/config.yml now
      # puts 'Setting up gh aliases'
      # sh 'gh alias set prs "f -p"'
      # sh 'gh alias set l "f -l"'
    end
  end

  task :clean do
    sh "rm -f #{home('.config/git')}"
    sh "rm -f #{home('.config/gh')}"
    sh "rm -f #{home('.config/gh-dash')}"
    sh "rm -rf #{home('.local/state/git')}"
  end

  desc 'Update all the git submodules in this repository'
  task :update do
    if which('gh')
      puts 'Updating gh extensions'.green
      sh 'gh extension upgrade --all'
    end
  end
end

task all: [:git]
task update: ['git:update']
task clean: ['git:clean']
# task update: ['git:update']
