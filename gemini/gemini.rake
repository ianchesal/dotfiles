desc 'Install gemini dotfiles'
task gemini: ['gemini:all']

NPM_PACKAGE = '@google/gemini-cli'.freeze

namespace :gemini do
  task all: [:config, :install]

  task :config do
    puts 'No-op for now'
    # dolink(home('.gemini'), root('gemini'))
  end

  task :install do
    mkdir_if_needed home('.npm-global')
    sh "npm config set prefix  #{home('.npm-global')}"
    sh "npm install -g #{NPM_PACKAGE}"
  end

  task :update do
    if File.exist?(File.expand_path('~/.npm-global/bin/gemini'))
      puts 'Update: gemini'.green
      sh '~/.npm-global/bin/gemini update'
    else
      puts 'No updates to gemini components -- no gemini CLI found'.red
    end
  end

  task :clean do
    puts 'No-op for now'
    sh "rm -f #{home('.gemini')}"
    if File.exist?(File.expand_path('~/.npm-global/bin/gemini'))
      sh "npm config set prefix  #{home('.npm-global')}"
      sh "npm uninstall -g #{NPM_PACKAGE}"
    end
  end
end

# task all: [:gemini]
task update: ['gemini:update']
task clean: ['gemini:clean']
