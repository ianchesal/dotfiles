desc 'Install oh-my-posh dotfiles'
task ohmyposh: ['ohmyposh:dir']

namespace :ohmyposh do
  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/oh-my-posh'), root('oh-my-posh'))
  end

  task :clean do
    sh "rm -f #{home('.config/oh-my-posh')}"
    sh "rm -f #{home('.cache/oh-my-posh')}"
  end
end

task all: [:ohmyposh]
task clean: ['ohmyposh:clean']
