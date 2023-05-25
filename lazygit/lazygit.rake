desc 'Install neovim dotfiles'
task lazygit: ['lazygit:all']

namespace :lazygit do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/lazygit'), root('lazygit'))
  end

  task :clean do
    sh "rm -f #{home('.config/lazygit')}"
    sh "rm -rf #{home('.local/share/lazygit')}"
    sh "rm -rf #{home('.local/state/lazygit')}"
    sh "rm -rf #{home('.cache/lazygit')}"
  end
end

task all: [:lazygit]
task clean: ['lazygit:clean']
