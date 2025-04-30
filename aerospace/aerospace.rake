desc 'Install aerospace dotfiles'
task aerospace: ['aerospace:all']

namespace :aerospace do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/aerospace'), root('aerospace'))
  end

  task :clean do
    sh "rm -f #{home('.config/aerospace')}"
    sh "rm -rf #{home('.local/state/aerospace')}"
    sh "rm -rf #{home('.local/share/aerospace')}"
  end

  desc 'Update all the aerospace submodules in this repository'
  task :update do
    puts 'Update: aerospace submodules'.green
    puts 'Just kidding. There are no submodules in this repo.'
  end
end

task all: [:aerospace]
task clean: ['aerospace:clean']
# task update: ['aerospace:update']
