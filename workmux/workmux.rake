desc 'Install workmux dotfiles'
task workmux: ['workmux:dir', 'workmux:install']

namespace :workmux do
  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/workmux'), root('workmux'))
  end

  task :install do
    sh 'brew install raine/workmux/workmux'
  end

  task :update do
    puts 'Nothing to update for workmux'.red
  end

  task :clean do
    sh 'brew uninstall workmux'
  end
end

task all: [:workmux]
task update: ['workmux:update']
task clean: ['workmux:clean']
