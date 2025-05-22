desc 'Install claude dotfiles'
task claude: ['claude:all']

namespace :claude do
  task all: [:config, :install]

  task :config do
    mkdir_if_needed home('.config')
    dolink(home('.config/claude'), root('claude'))
  end

  task :install do
    mkdir_if_needed home('.npm-global')
    sh "npm config set prefix  #{home('.npm-global')}"
    sh 'npm install -g @anthropic-ai/claude-code'
  end

  task :update do
    sh '~/.npm-global/bin/claude update' if File.exist?(File.expand_path('~/.npm-global/bin/claude'))
  end

  task :clean do
    sh "rm -f #{home('.config/claude')}"
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean'
