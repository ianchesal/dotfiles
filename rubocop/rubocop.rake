desc 'Install all Rubocop-related dotfiles'
task rubocop: ['rubocop:all']

RUBOCOP = 'rubocop --display-cop-names --color'.freeze
# The Rakefile plus every tool's *.rake, all root()-anchored: rubocop resolves
# these paths against its own cwd, which is not the repo when rake was handed
# `-f <path>` from elsewhere.
FILES_TO_CHECK = ([root('Rakefile')] + Dir.glob(root('*', '*.rake'))).freeze

namespace :rubocop do
  task all: [:rubocop]

  task :rubocop do
    dolink(home('.rubocop.yml'), root('rubocop', 'rubocop.yml'))
  end

  task :clean do
    clean_restore home('.rubocop.yml')
  end

  desc 'Run Rubocop checks'
  task :check do
    sh "#{RUBOCOP} " + FILES_TO_CHECK.join(' ')
  end

  desc 'Auto-correct Rubocop failures'
  task :auto_correct do
    sh "#{RUBOCOP} --auto-correct " + FILES_TO_CHECK.join(' ')
  end
end

task all: [:rubocop]
task clean: ['rubocop:clean']
