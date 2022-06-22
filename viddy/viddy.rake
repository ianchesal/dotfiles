desc 'Install all viddy dotfiles'
task viddy: ['viddy:all']

namespace :viddy do
  task all: [:viddy]

  task :viddy do
    mkdir_if_needed home('.config')
    dolink(home('.config/viddy.toml'), root('viddy', 'viddy.toml'))
  end

  task :clean do
    clean_restore home('.config/viddy.toml')
  end
end

task all: [:viddy]
task clean: ['viddy:clean']
