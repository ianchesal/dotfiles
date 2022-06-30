desc 'Install kitty terminal configuration'
task kitty: ['kitty:conf']

namespace :kitty do
  task :conf do
    mkdir_if_needed home('.config/kitty/')
    Dir['kitty/*.conf'].each do |cf|
      dolink(home(".config/#{cf}"), root(cf))
    end
    FileUtils.cp(root('kitty/macos-launch-services-cmdline'), home('.config/kitty/macos-launch-services-cmdline'))
  end

  task :clean do
    Dir['kitty/*.conf'].each do |cf|
      clean_restore home(".config/#{cf}")
    end
  end
end

task all: [:kitty]
task clean: ['kitty:clean']
