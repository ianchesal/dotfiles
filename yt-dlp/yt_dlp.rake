desc 'Install yt-dlp configuration'
task ytdlp: ['ytdlp:conf']

namespace :ytdlp do
  task :conf do
    mkdir_if_needed home('.config/yt-dlp/')
    dolink(home('.config/yt-dlp/config'), root('yt-dlp/yt-dlp.conf'))
  end

  task :clean do
    clean_restore home('.config/yt-dlp/config')
  end

  desc 'Update yt-dlp'
  task :update do
    if which('yt-dlp')
      puts 'Updating yt-dlp'.green
      sh 'yt-dlp -U'
    end
  end
end

task all: [:ytdlp]
task update: ['ytdltp:update']
task clean: ['ytdlp:clean']
