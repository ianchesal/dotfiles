desc 'Install fish shell configuration'
task fish: ['fish:conf']

namespace :fish do
  task :conf do
    mkdir_if_needed home('.config')
    dolink(home('.config/fish'), root('fish'))
  end

  task :clean do
    sh "rm -f #{home('.config/fish')}"
  end
end

task all: [:fish]
task clean: ['fish:clean']
