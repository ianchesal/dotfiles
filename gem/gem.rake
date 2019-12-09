desc 'Install all gem-related dotfiles'
task gem: ['gem:all']

namespace :gem do
  task all: [:gemrc]

  task gemrc: [:gemdir] do
    dolink(home('.gemrc'), root('gem', 'gemrc'))
  end

  task :gemdir do
    mkdir_if_needed home('.gem')
  end

  task :clean do
    clean_restore home('.rubocop.yml')
  end
end

task all: [:gem]
task clean: ['gem:clean']
