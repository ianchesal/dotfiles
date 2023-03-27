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
end

task all: [:ytdlp]
task clean: ['ytdlp:clean']
