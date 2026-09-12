# frozen_string_literal: true

namespace :git do
  desc 'Upgrade installed gh CLI extensions'
  task :update do
    if which('gh')
      puts 'Updating gh extensions'.green
      sh 'gh extension upgrade --all'
    end
  end
end

task update: ['git:update']
