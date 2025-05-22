desc 'Install codex dotfiles'
task codex: ['codex:all']

namespace :codex do
  task all: [:config, :install]

  task :config do
    mkdir_if_needed home('.config')
    dolink(home('.config/codex'), root('codex'))
  end

  task :install do
    mkdir_if_needed home('.npm-global')
    sh "npm config set prefix  #{home('.npm-global')}"
    sh 'npm install -g @openai/codex'
  end

  task :clean do
    sh "rm -f #{home('.config/codex')}"
  end
end

task all: [:codex]
task clean: ['codex:clean']
