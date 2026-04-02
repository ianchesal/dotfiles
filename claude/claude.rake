desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_SETTINGS_FILE = home('.claude.json').freeze

namespace :claude do
  task all: [:dirs, :install, :permissions]

  task :dirs do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    sh 'curl -fsSL https://claude.ai/install.sh | bash'
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
    if which('claude')
      puts 'Update: claude'.green
      old_version = `claude --version 2>/dev/null`.strip
      sh 'claude update'
      new_version = `claude --version 2>/dev/null`.strip
      if old_version != new_version
        puts "claude updated #{old_version} -> #{new_version}, regenerating completions...".yellow
        Rake::Task['claude:gen_completions'].invoke
      end
    else
      puts 'No updates to claude components -- claude not found'.red
    end
  end

  desc 'Regenerate zsh/completions/_claude from claude --help'
  task :gen_completions do
    sh root('script', 'gen-claude-completions').to_s
  end

  task :clean do
    sh "rm -f #{home('.claude')}"
    sh "rm -f #{home('.local/bin/claude')}"
    sh "rm -rf #{home('.local/share/claude')}"
  end
end

task all: [:claude]
task update: ['claude:update']
task clean: ['claude:clean']
