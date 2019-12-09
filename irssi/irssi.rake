desc 'Install irssi dotfiles'
task irssi: ['irssi:all']

namespace :irssi do
  task :all do
    dolink(home('.irssi'), root('irssi'))
  end

  task :clean do
    clean_restore home('.irssi')
  end
end

task all: [:irssi]
task clean: ['irssi:clean']
