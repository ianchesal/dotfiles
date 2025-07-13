desc 'Install opencode dotfiles'
task opencode: ['opencode:all']

OPENCODE_NPM_PACKAGE = 'opencode-ai'.freeze

namespace :opencode do
  task all: [:dirs, :install]

  task :dirs do
    dolink(home('.config/opencode'), root('opencode'))
  end

  task :install do
    npm_install(OPENCODE_NPM_PACKAGE)
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/opencode'))
      puts 'Update: opencode'.green
      sh '~/.npm-global/bin/opencode upgrade'
    else
      puts 'No updates to opencode components -- no opencode CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.config/opencode')}"
    sh "rm -rf #{home('.local/share/opencode')}"
    npm_uninstall(OPENCODE_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/opencode'))
  end
end

task all: [:opencode]
task update: ['opencode:update']
task clean: ['opencode:clean']
