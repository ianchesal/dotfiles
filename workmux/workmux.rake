# frozen_string_literal: true

namespace :workmux do
  task :update do
    puts 'Nothing to update for workmux'.red
  end
end

task update: ['workmux:update']
