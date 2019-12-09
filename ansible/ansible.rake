desc 'Install ansible dotfiles'
task ansible: ['ansible:all']

namespace :ansible do
  task all: [:config]

  task :config do
    dolink(home('.ansible.cfg'), root('ansible', 'ansible.cfg'))
  end

  task :clean do
    clean_restore home('.ansible.cfg')
    clean_restore home('.gitconfig')
  end
end

task all: [:ansible]
task clean: ['ansible:clean']
