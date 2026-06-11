desc 'Install neovim dotfiles'
task nvim: ['nvim:all']

namespace :nvim do
  task all: [:dir]

  task :dir do
    mkdir_if_needed home('.config')
    dolink(home('.config/nvim'), root('nvim'))
  end

  desc 'Update nvim plugins (30-day delayed) and Mason packages'
  task :update do
    # These files get big. Nuke them regularly.
    %w[lsp.log noice.log mason.log conform.log log].each do |logfile|
      sh "rm -f #{home(".local/state/nvim/#{logfile}")}"
    end
    # -u NONE is load-bearing: init.lua must not pre-register vim.pack specs
    # (re-adds are no-ops and would freeze update targets at startup pins).
    sh "nvim --headless -u NONE -l #{root('nvim', 'scripts', 'update.lua')}"
    # Parity with the old task: MasonUpdate refreshes the registry only, not
    # installed packages (those need MasonUpdateAll + its completion autocmd).
    sh 'nvim --headless "+MasonUpdate" +qa'
  end

  desc 'Preview which plugin updates are eligible without applying'
  task :outdated do
    sh "nvim --headless -u NONE -l #{root('nvim', 'scripts', 'update.lua')} --dry-run"
  end

  desc 'Check for and commit nvim dependency updates'
  task :commit do
    pins = root('nvim', 'pins.json')
    lock = root('nvim', 'nvim-pack-lock.json')
    pins_changed = !system("git diff --quiet HEAD -- #{pins}")
    lock_changed = !system("git diff --quiet HEAD -- #{lock}")
    if !pins_changed && !lock_changed
      puts 'No changes to nvim dependencies'.green
    elsif pins_changed ^ lock_changed
      # Invariant: pins.json and the vim.pack lockfile travel in one commit.
      # One changing alone means drift — refuse and reconverge first.
      abort 'Only one of pins.json/nvim-pack-lock.json changed — run `rake nvim:update` to reconverge, then retry'.red
    else
      puts 'Found changes in nvim dependencies:'.blue
      system("git --no-pager diff --stat #{pins} #{lock}")
      system("git add #{pins} #{lock}")
      # Pathspec'd commit: never sweep up unrelated staged changes
      system("git commit -m 'Deps updates' -- #{pins} #{lock}")
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
