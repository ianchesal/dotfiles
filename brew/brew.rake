namespace :brew do
  ENV['HOMEBREW_NO_ENV_HINTS'] = '1'

  desc 'Update homebrew installed packages'
  task :update do
    if which('brew')
      puts 'Update: Homebrew'.green
      sh 'brew upgrade --force && brew cleanup'
    else
      puts 'Skipping: Homebrew update -- no brew command found'.blue
    end
  end
end

task update: ['brew:update']
