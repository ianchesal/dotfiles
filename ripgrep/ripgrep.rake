desc 'Install ripgrep dotfiles'
task ripgrep: ['ripgrep:all']

namespace :ripgrep do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/ripgrep'), root('ripgrep'))
  end

  task :clean do
    sh "rm -f #{home('.config/ripgrep')}"
  end
end

task all: [:ripgrep]
task clean: ['ripgrep:clean']
