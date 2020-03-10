namespace :brew do
  desc 'Update homebrew installed packages'
  task :update do
    puts 'Update: Homebrew'.green
    sh 'brew upgrade'
  end
end

task update: ['brew:update']
