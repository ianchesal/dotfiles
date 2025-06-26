desc 'Install gemini dotfiles'
task gemini: ['gemini:all']

GEMINI_NPM_PACKAGE = '@google/gemini-cli'.freeze

namespace :gemini do
  task all: [:config, :install]

  task :config do
    mkdir_if_needed home('.gemini')
    dolink(home('.gemini/settings.json'), root('gemini/settings.json'))
  end

  task :install do
    npm_install(GEMINI_NPM_PACKAGE)
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/gemini'))
      puts 'Update: gemini'.green
      npm_update(GEMINI_NPM_PACKAGE)
    else
      puts 'No updates to gemini components -- no gemini CLI found'.red
    end
  end

  task :clean do
    puts 'No-op for now'
    sh "rm -rf #{home('.gemini')}"
    npm_uninstall(GEMINI_NPM_PACKAGE) if File.exist?(File.expand_path('~/.npm-global/bin/gemini'))
  end
end

# task all: [:gemini]
task update: ['gemini:update']
task clean: ['gemini:clean']
