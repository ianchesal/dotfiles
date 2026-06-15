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
    else
      # Invariant: only commit consistent states — every pin rev in pins.json
      # must agree with the lockfile rev for that plugin. The lockfile holds
      # full 40-char SHAs; pins.json also holds full SHAs — compare directly.
      # Observation-only runs (new observed entries, no pin movement) are fine:
      # those plugins still agree because pin.rev == lock.rev.
      require 'json'
      pin_revs = JSON.parse(File.read(pins))['plugins'].transform_values { |p| p.dig('pin', 'rev') }.compact
      lock_revs = JSON.parse(File.read(lock))['plugins'].transform_values { |p| p['rev'] }
      disagreements = pin_revs.reject do |name, rev|
        lock_revs[name].nil? || rev.start_with?(lock_revs[name]) || lock_revs[name].start_with?(rev)
      end
      unless disagreements.empty?
        abort "pins.json and nvim-pack-lock.json disagree for: #{disagreements.keys.join(', ')} — run `rake nvim:update` to reconverge, then retry".red
      end
      puts 'Found changes in nvim dependencies:'.blue
      system("git --no-pager diff --stat #{pins} #{lock}")
      system("git add #{pins} #{lock}")
      # Pathspec'd commit: never sweep up unrelated staged changes
      system("git commit -m 'Deps updates' -- #{pins} #{lock}")
      system('git push')
      puts 'Successfully committed and pushed dependency updates'.green
    end
  end

  desc 'Remove on-disk plugin clones not in pins.json (sync after pulling deletions on a fresh machine)'
  task :prune do
    require 'json'
    authorized = JSON.parse(File.read(root('nvim', 'pins.json')))['plugins'].keys.to_set
    pack_dir = File.expand_path('~/.local/share/nvim/site/pack/core/opt')
    orphans = Dir.entries(pack_dir).reject { |e| e.start_with?('.') }.reject { |e| authorized.include?(e) }
    if orphans.empty?
      puts 'No orphaned plugins found'.green
    else
      puts "Removing orphaned plugins: #{orphans.join(', ')}".yellow
      list = orphans.map { |o| "'#{o}'" }.join(', ')
      sh "nvim --headless -u NONE \"+lua vim.pack.del({ #{list} })\" +qa"
      puts 'Done'.green
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
