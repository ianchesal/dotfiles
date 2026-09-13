# frozen_string_literal: true

namespace :ytdlp do
  desc 'Update yt-dlp'
  task :update do
    if which('yt-dlp')
      puts 'Updating yt-dlp'.green
      sh 'yt-dlp -U'
    end
  end
end

task update: ['ytdlp:update']
