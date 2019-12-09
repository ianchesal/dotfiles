desc 'Install bash dotfiles'
task bash: ['bash:all']

namespace :bash do
  task all: [:rc, :inputrc, :profile]

  task :rc do
    dolink(home('.bashrc'), root('bash', 'bashrc'))
  end

  task :inputrc do
    dolink(home('.inputrc'), root('bash', 'inputrc'))
  end

  task :profile do
    dolink(home('.bash_profile'), root('bash', 'bash_profile'))
  end

  task :clean do
    clean_restore home('.bash_profile')
    clean_restore home('.inputrc')
    clean_restore home('.bashrc')
  end
end

task all: [:bash]
task clean: ['bash:clean']
