desc 'Install oh-my-posh configuration'
task ohmyposh: ['ohmyposh:all']

namespace :ohmyposh do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/ohmyposh'), root('ohmyposh'))
  end

  task :clean do
    sh "rm -f #{home('.config/ohmyposh')}"
  end
end

task all: [:ohmyposh]
task clean: ['ohmyposh:clean']
