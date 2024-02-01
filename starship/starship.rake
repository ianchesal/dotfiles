desc 'Install starship dotfiles'
task starship: ['starship:all']

namespace :starship do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/starship.toml'), root('starship', 'starship.toml'))
  end

  task :clean do
    sh "rm -f #{home('.config/starship.toml')}"
    # sh "rm -rf #{home('.local/state/starship')}"
    # sh "rm -rf #{home('.local/share/starship')}"
  end

  desc 'Update all the starship submodules in this repository'
  task :update do
    puts 'Update: starship submodules'.green
    puts 'Just kidding. There are no submodules in this repo.'
  end
end

task all: [:starship]
task clean: ['starship:clean']
task update: ['starship:update']
