desc 'Install oh-my-posh configuration'
task ohmyposh: ['ohmyposh:all']

namespace :ohmyposh do
  desc 'Check for oh-my-posh updates'
  task :check_update do
    if which('brew')
      outdated = `brew outdated --verbose oh-my-posh`.strip
      if outdated.empty?
        puts 'No update to oh-my-posh found'.blue
      else
        puts "\n\n"
        puts '*'.green * 80
        puts 'ATTENTION: oh-my-posh update available!'.yellow.bold
        puts "Details: #{outdated}".yellow
        puts "Run 'rake ohmyposh:update' to update".yellow
        puts '*'.green * 80
        puts "\n"
      end
    end
  end

  desc 'Update oh-my-posh via Homebrew'
  task :update do
    if which('brew')
      puts 'Update: oh-my-posh'.green
      sh 'brew upgrade oh-my-posh && brew cleanup'
    else
      puts 'Skipping: oh-my-posh update -- no brew command found'.blue
    end
  end

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
task update: ['ohmyposh:check_update']
task clean: ['ohmyposh:clean']
