desc 'Install claude dotfiles'
task claude: ['claude:all']

CLAUDE_SETTINGS_FILE = home('.claude.json').freeze

# Returns the installed claude-code deb version, or nil when the deb isn't installed.
#
# On Debian/WSL2 the claude-code deb owns /usr/bin/claude and apt drives its updates.
# Running the curl installer or `claude update` on such a box creates a competing copy,
# and because npm's global prefix can sit inside the asdf node tree, that copy lands
# ahead of /usr/bin on PATH and shadows the deb.
def apt_claude_version
  return nil unless OS.linux? && which('dpkg-query')

  status, version = `dpkg-query -W -f='${Status}|${Version}' claude-code 2>/dev/null`.split('|')
  return nil unless status.to_s.include?('install ok installed')

  version
end

namespace :claude do
  task all: [:dirs, :install, :permissions]

  task :dirs do
    dolink(home('.claude'), root('claude'))
  end

  task :install do
    if (deb_version = apt_claude_version)
      puts "claude-code #{deb_version} is apt managed, skipping the installer".yellow
      puts 'Install or upgrade it with: sudo apt update && sudo apt upgrade claude-code'.yellow
    else
      sh 'curl -fsSL https://claude.ai/install.sh | bash'
    end
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
    if (deb_version = apt_claude_version)
      puts "claude-code #{deb_version} is apt managed, skipping `claude update`".yellow
      puts 'Update it with: sudo apt update && sudo apt upgrade claude-code'.yellow
      puts 'Then regenerate completions with: rake claude:gen_completions'.yellow
    elsif which('claude')
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
