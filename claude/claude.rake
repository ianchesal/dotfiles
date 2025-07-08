desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_NPM_PACKAGE = '@anthropic-ai/claude-code'.freeze
CLAUDE_SETTINGS_FILE = root('claude/settings.json').freeze

namespace :claude do
  task all: [:dirs, :install, :settings, :permissions]

  task :dirs do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    npm_install(CLAUDE_NPM_PACKAGE)
  end

  task :settings do
    require 'json'

    default_config = {
      'autoUpdaterStatus' => 'disabled',
      'editorMode' => 'vim',
      'defaultMode' => 'plan'
    }

    if File.exist?(CLAUDE_SETTINGS_FILE)
      begin
        existing_settings = JSON.parse(File.read(CLAUDE_SETTINGS_FILE))
        existing_settings.merge!(default_config)
        File.write(CLAUDE_SETTINGS_FILE, JSON.pretty_generate(existing_settings))
        puts 'Updated claude settings with hooks configuration'.green
      rescue JSON::ParserError => e
        puts "Error parsing existing settings.json: #{e.message}".red
        puts 'Creating backup and writing new settings file'.yellow
        backup_file = "#{CLAUDE_SETTINGS_FILE}.backup.#{Time.now.to_i}"
        File.rename(CLAUDE_SETTINGS_FILE, backup_file)
        File.write(CLAUDE_SETTINGS_FILE, JSON.pretty_generate(default_config))
        puts "Backup created at #{backup_file}".yellow
      end
    else
      mkdir_if_needed(File.dirname(CLAUDE_SETTINGS_FILE))
      File.write(CLAUDE_SETTINGS_FILE, JSON.pretty_generate(default_config))
      puts 'Created new claude settings.json with hooks configuration'.green
    end
  end

  task :permissions do
    if File.exist?(CLAUDE_SETTINGS_FILE)
      current_mode = File.stat(CLAUDE_SETTINGS_FILE).mode & 0o777
      if current_mode != 0o600
        File.chmod(0o600, CLAUDE_SETTINGS_FILE)
        puts 'Set claude settings.json permissions to 600'.green
      end
    else
      puts 'No claude settings.json file found, skipping permissions check'.yellow
    end
  end

  task update: [:settings, :permissions] do
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
