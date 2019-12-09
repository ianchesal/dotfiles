desc 'Install curl dotfiles'
task curl: ['curl:rc']

namespace :curl do
  task :rc do
    dolink(home('.curlrc'), root('curl', 'curlrc'))
  end

  task :clean do
    clean_restore home('.curlrc')
  end
end

task all: [:curl]
task clean: ['curl:clean']
