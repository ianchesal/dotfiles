desc 'Install claude dotfiles'
task claude: ['claude:all']

namespace :claude do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/claude'), root('claude'))
  end

  task :node do
    mkdir_if_needed home('.npm-global')
    sh "npm config set prefix  #{home('.npm-global')}"
    sh 'npm install -g @anthropic-ai/claude-code'
  end

  task :clean do
    sh "rm -f #{home('.config/claude')}"
  end
end

task all: [:claude]
task clean: ['claude:clean']
