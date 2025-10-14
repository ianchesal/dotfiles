namespace :brew do
  ENV['HOMEBREW_NO_ENV_HINTS'] = '1'

  desc 'Update homebrew installed packages'
  task :update do
    if which('brew')
      puts 'Update: Homebrew'.green

      # Get pinned packages to exclude from upgrades
      pinned = `brew list --pinned --quiet 2>/dev/null`.strip.split("\n")

      # Get outdated packages and filter out oh-my-posh and pinned packages
      outdated = `brew outdated --quiet`.strip.split("\n")
      outdated.reject! { |pkg| pkg == 'oh-my-posh' || pinned.include?(pkg) }

      if outdated.empty?
        puts 'No outdated formulas to upgrade'.blue
      else
        outdated_str = outdated.join(' ')
        puts "Upgrading formulas: #{outdated_str}".green
        puts "Skipping pinned packages: #{pinned.join(', ')}".blue unless pinned.empty?
        sh "brew upgrade --force #{outdated_str} && brew cleanup"
      end
    else
      puts 'Skipping: Homebrew update -- no brew command found'.blue
    end
  end
end

task update: ['brew:update']
