desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_NPM_PACKAGE = '@anthropic-ai/claude-code'.freeze

namespace :claude do
  task all: [:config, :install]

  task :config do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    npm_install(CLAUDE_NPM_PACKAGE)
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
    npm_uninstall(CLAUDE_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/claude'))
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean']
