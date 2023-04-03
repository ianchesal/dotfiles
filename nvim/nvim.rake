desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    sh "git clone https://github.com/NvChad/NvChad #{home('.config/nvim')} --depth 1"
    dolink(home('.config/nvim/lua/custom'), root('nvim/custom'))
  end

  desc 'Update plugins'
  task :update do
    puts 'Update: NvChad for Neovim'.green
    sh "nvim -c 'NvChadUpdate' -c q"
  end

  task :clean do
    sh "rm -rf #{home('.config/nvim')}"
    sh "rm -rf #{home('.local/share/nvim')}"
  end
end

task all: [:nvim]
task clean: ['nvim:clean']
task update: ['nvim:update']
