desc 'Install zellij dotfiles'
task zellij: ['zellij:all']

namespace :zellij do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/zellij'), root('zellij'))
  end

  task :clean do
    sh "rm -f #{home('.config/zellij')}"
  end
end

# task all: [:zellij]
# task clean: ['zellij:clean']
