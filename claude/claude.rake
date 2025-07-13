desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_NPM_PACKAGE = '@anthropic-ai/claude-code'.freeze
CLAUDE_SETTINGS_FILE = home('.claude.json').freeze

namespace :claude do
  task all: [:dirs, :install, :permissions]

  task :dirs do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    npm_install(CLAUDE_NPM_PACKAGE)
  end

  task :permissions do
    if File.exist?(CLAUDE_SETTINGS_FILE)
      current_mode = File.stat(CLAUDE_SETTINGS_FILE).mode & 0o777
      if current_mode != 0o600
        File.chmod(0o600, CLAUDE_SETTINGS_FILE)
        puts "Set #{CLAUDE_SETTINGS_FILE} permissions to 600".green
      end
    else
      puts "No #{CLAUDE_SETTINGS_FILE} file found, skipping permissions check".yellow
    end
  end

  task update: [:permissions] do
    if File.exist?(File.expand_path('~/.npm-global/bin/claude'))
      puts 'Update: claude'.green
      sh '~/.npm-global/bin/claude update'
    else
      puts 'No updates to claude components -- no claude CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.claude')}"
    # sh "rm -f #{home(CLAUDE_SETTINGS_FILE)}"
    npm_uninstall(CLAUDE_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/claude'))
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean']
