desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/nvim'), root('nvim'))
  end

  task :update do
    # This file gets big. Nuke it regularly.
    sh "rm -f #{home('.local/state/nvim/lsp.log')}"
    # sh 'nvim --headless "+Lazy! sync" +qa'
  end

  task :clean do
    sh "rm -f #{home('.config/nvim')}"
    sh "rm -rf #{home('.local/share/nvim')}"
    sh "rm -rf #{home('.local/state/nvim')}"
    sh "rm -rf #{home('.cache/nvim')}"
  end
end

task all: [:nvim]
task clean: ['nvim:clean']
task update: ['nvim:update']
