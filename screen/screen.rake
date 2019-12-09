desc 'Install screen dotfiles'
task screen: ['screen:rc']

namespace :screen do
  task :rc do
    dolink(home('.screenrc'), root('screen', 'screenrc'))
  end

  task :clean do
    clean_restore home('.screenrc')
  end
end

task all: [:screen]
task clean: ['screen:clean']
