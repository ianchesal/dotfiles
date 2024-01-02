desc 'Install all starship dotfiles'
task starship: ['starship:all']

namespace :starship do
  task all: [:starship]

  task :starship do
    mkdir_if_needed home('.config')
    dolink(home('.config/starship.toml'), root('starship', 'starship.toml'))
  end

  task :clean do
    clean_restore home('.config/starship.toml')
  end
end

task all: [:starship]
task clean: ['starship:clean']
