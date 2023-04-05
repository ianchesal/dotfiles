desc 'Install kitty terminal configuration'
task kitty: ['kitty:conf']

namespace :kitty do
  task :conf do
    mkdir_if_needed home('.config')
    dolink(home('.config/kitty'), root('kitty'))
  end

  task :clean do
    sh "rm -f #{home('.config/kitty')}"
  end
end

task all: [:kitty]
task clean: ['kitty:clean']
