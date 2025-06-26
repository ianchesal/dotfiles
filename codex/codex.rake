desc 'Install codex dotfiles'
task codex: ['codex:all']

CODEX_NPM_PACKAGE = '@openai/codex'.freeze

namespace :codex do
  task all: [:config, :install]

  task :config do
    mkdir_if_needed home('.config')
    dolink(home('.config/codex'), root('codex'))
  end

  task :install do
    npm_install(CODEX_NPM_PACKAGE)
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/codex'))
      puts 'Update: codex'.green
      npm_update(CODEX_NPM_PACKAGE)
    else
      puts 'No updates to codex components -- no codex CLI found'.red
    end
  end

  task :clean do
    sh "rm -f #{home('.config/codex')}"
    npm_uninstall(CODEX_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/codex'))
  end
end

# task all: [:codex]
task update: ['codex:update']
task clean: ['codex:clean']
