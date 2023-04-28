desc 'Install karabiner dotfiles'
task karabiner: ['karabiner:all']

namespace :karabiner do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/karabiner'), root('karabiner'))
  end

  task :clean do
    sh "rm -f #{home('.config/karabiner')}"
    sh "rm -rf #{home('.local/state/karabiner')}"
    sh "rm -rf #{home('.local/share/karabiner')}"
  end

  desc 'Update all the karabiner submodules in this repository'
  task :update do
    puts 'Update: karabiner submodules'.green
    puts 'Just kidding. There are no submodules in this repo.'
  end
end

task all: [:karabiner]
task clean: ['karabiner:clean']
# task update: ['karabiner:update']
