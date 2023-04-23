desc 'Install starship dotfiles'
task starship: ['starship:all']

namespace :starship do
  task all: [:toml]

  task :toml do
    mkdir_if_needed home('.config')
    dolink(home('.config/starship.toml'), root('starship/starship.toml'))
    sh 'curl -sS https://starship.rs/install.sh | sh'
  end

  desc 'Update starship'
  task :update do
    sh 'curl -sS https://starship.rs/install.sh | sh'
  end

  task :clean do
    sh "rm -f #{home('.config/starship.toml')}"
    sh "rm -rf #{home('.local/share/starship')}"
    sh "rm -rf #{home('.local/state/starship')}"
  end
end

task all: [:starship]
task clean: ['starship:clean']
task update: ['starship:update']
