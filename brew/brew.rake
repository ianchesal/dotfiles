namespace :brew do
  desc 'Update homebrew installed packages'
  task :update do
    if which('brew')
      puts 'Update: Homebrew'.green
      sh 'brew upgrade --force'
    else
      puts 'Skipping: Homebrew update -- no brew command found'.blue
    end
  end
end

task update: ['brew:update']
