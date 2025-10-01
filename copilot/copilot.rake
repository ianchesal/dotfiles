desc 'Install copilot dotfiles'
task copilot: ['copilot:all']

COPILOT_NPM_PACKAGE = '@github/copilot'.freeze

namespace :copilot do
  task all: [:dirs, :install]

  task :dirs do
    dolink(home('.config/.copilot'), root('copilot'))
  end

  task :install do
    npm_install(COPILOT_NPM_PACKAGE)
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/copilot'))
      puts 'Update: copilot'.green
      npm_install(COPILOT_NPM_PACKAGE)
    else
      puts 'No updates to copilot components -- no copilot CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.config/.copilot')}"
    # sh "rm -f #{home(COPILOT_SETTINGS_FILE)}"
    npm_uninstall(COPILOT_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/copilot'))
  end
end

task all: [:copilot]
task update: ['copilot:update']
task clean: ['copilot:clean']
