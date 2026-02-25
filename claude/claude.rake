desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_SETTINGS_FILE = home('.claude.json').freeze

namespace :claude do
  task all: [:dirs, :install, :permissions]

  task :dirs do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    sh 'brew install --cask claude-code'
    FileUtils.mkdir_p(home('.local/bin'))
    dolink(home('.local/bin/claude'), which('claude'))
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
    if which('brew') && system('brew list --cask claude-code > /dev/null 2>&1')
      puts 'Update: claude'.green
      sh 'brew upgrade claude-code'
    else
      puts 'No updates to claude components -- claude-code brew cask not found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.claude')}"
    sh "rm -f #{home('.local/bin/claude')}"
    sh "rm -rf #{home('.local/share/claude')}"
    sh 'brew remove claude-code'
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean']
