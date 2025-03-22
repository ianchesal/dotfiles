desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/nvim'), root('nvim'))
  end

  task :update do
    # These files get big. Nuke them regularly.
    %w[lsp.log noice.log mason.log conform.log neotest.log nio.log log].each do |logfile|
      path = ".local/state/nvim/#{logfile}"
      sh "rm -f #{home(path)}"
    end
    sh 'nvim --headless "+Lazy! sync" +qa'
    sh 'nvim --headless "+MasonUpdate" +qa'
  end

  desc 'Check for and commit nvim dependency updates'
  task :commit do
    lazy_lock = root('nvim', 'lazy-lock.json')
    if system("git diff --quiet HEAD -- #{lazy_lock}")
      puts 'No changes to nvim dependencies'.green
    else
      puts 'Found changes in nvim dependencies:'.blue
      system("git --no-pager diff #{lazy_lock}")
      puts "\nCommitting changes...".blue
      system("git add #{lazy_lock}")
      system('git commit -m "Deps updates"')
      system('git push')
      puts 'Successfully committed and pushed dependency updates'.green
    end
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
