desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

GEMS = %w[neovim solargraph].freeze

namespace :nvim do
  task all: [:dir, :deps]

  task :dir do
    mkdir_if_needed home('.config')
    sh "git clone https://github.com/NvChad/NvChad #{home('.config/nvim')} --depth 1"
    dolink(home('.config/nvim/lua/custom'), root('nvim/custom'))
  end

  task :deps do
    GEMS.each { |g| sh "gem install #{g}" }
  end

  desc 'Update plugins'
  task :update do
    puts 'Update: NvChad for Neovim'.green
    GEMS.each { |g| sh "gem update #{g}" }
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
