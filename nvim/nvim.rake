desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir, :deps]

  task :dir do
    mkdir_if_needed home('.config')
    sh "git clone https://github.com/NvChad/NvChad #{home('.config/nvim')} --depth 1"
    dolink(home('.config/nvim/lua/custom'), root('nvim/custom'))
  end

  task update: 'lsp:update' do
    puts 'Update: NvChad for Neovim'.green
    # sh "nvim -c 'NvChadUpdate' -c q"
    # sh "nvim -c 'TSInstallSync all' -c q"
  end

  task :clean do
    sh "rm -f #{home('.config/nvim')}"
    sh "rm -rf #{home('.local/share/nvim')}"
    sh "rm -rf #{home('.local/state/nvim')}"
  end
end

task all: [:nvim]
task clean: ['nvim:clean']
task update: ['nvim:update']
