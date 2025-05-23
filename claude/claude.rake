desc 'Install claude dotfiles'
task claude: ['claude:all']

namespace :claude do
  task all: [:config, :install]

  task :config do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    mkdir_if_needed home('.npm-global')
    sh "npm config set prefix  #{home('.npm-global')}"
    sh 'npm install -g @anthropic-ai/claude-code'
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/claude'))
      puts 'Update: claude'.green
      sh '~/.npm-global/bin/claude update'
    else
      puts 'No updates to claude components -- no claude CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.claude')}"
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean']
