desc 'Install all Rubocop-related dotfiles'
task rubocop: ['rubocop:all']

namespace :rubocop do
  task all: [:rubocop]

  task :rubocop do
    dolink(home('.rubocop.yml'), root('rubocop', 'rubocop.yml'))
  end

  task :clean do
    clean_restore home('.rubocop.yml')
  end

  RUBOCOP = 'rubocop --display-cop-names --color'.freeze
  FILES_TO_CHECK = %w(Rakefile).freeze

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
