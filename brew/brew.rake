namespace :brew do
  ENV['HOMEBREW_NO_ENV_HINTS'] = '1'

  desc 'Update homebrew installed packages'
  task :update do
    if which('brew')
      puts 'Update: Homebrew'.green
      outdated = `brew outdated --quiet | grep -v oh-my-posh`.strip
      if outdated.empty?
        puts 'No outdated formulas to upgrade'.blue
      else
        puts "Upgrading formulas: #{outdated}".green
        sh "brew upgrade --force #{outdated} && brew cleanup"
      end
    else
      puts 'Skipping: Homebrew update -- no brew command found'.blue
    end
  end
end

task update: ['brew:update']
