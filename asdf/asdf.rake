desc 'Install all asdf dotfiles'
task asdf: ['asdf:all']

namespace :asdf do
  task all: [:asdf]

  task :asdf do
    dolink(home('.asdfrc'), root('asdf', 'asdfrc'))
    dolink(home('.tool-versions'), root('asdf', 'tool-versions'))
  end

  task :update do
    puts 'Update: asdf plugins'.green
    sh 'asdf plugin update --all'
  end

  task :clean do
    clean_restore home('.asdfrc')
  end
end

task all: [:asdf]
task update: ['asdf:update']
task clean: ['asdf:clean']
