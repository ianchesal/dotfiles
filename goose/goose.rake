desc 'Install goose dotfiles'
task goose: ['goose:all']

namespace :goose do
  task all: [:config, :install]

  task :config do
    mkdir_if_needed home('.config')
    dolink(home('.config/goose'), root('goose'))
  end

  task :install do
    sh 'curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash'
  end

  task :update do
    if File.exist?(File.expand_path('~/.local/bin/goose'))
      sh 'goose update'
    else
      puts 'No updates to goose -- no goose CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.config/goose')}"
    sh "rm -f #{home('.local/bin/goose')}" if File.exist?(File.expand_path('~/.local/bin/goose'))
  end
end

task all: [:goose]
task update: ['goose:update']
task clean: ['goose:clean']
