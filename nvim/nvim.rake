desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/nvim'), root('nvim'))
  end

  desc 'Update plugins'
  task :update do
    puts 'Update: neovim plugins with packer'.green
    # sh "nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'"
  end

  task :clean do
    sh "rm -rf #{home('.config/nvim')}"
  end
end

task all: [:nvim]
task clean: ['nvim:clean']
task update: ['nvim:update']
