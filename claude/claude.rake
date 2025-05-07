desc 'Install claude dotfiles'
task claude: ['claude:all']

namespace :claude do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/claude'), root('claude'))
  end

  task :clean do
    sh "rm -f #{home('.config/claude')}"
  end
end

task all: [:claude]
task clean: ['claude:clean']
