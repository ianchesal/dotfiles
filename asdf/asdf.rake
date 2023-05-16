desc 'Install all asdf dotfiles'
task asdf: ['asdf:all']

namespace :asdf do
  task all: [:asdf]

  task :asdf do
    sh 'git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3' unless File.exist?(home('.asdf'))
    dolink(home('.asdfrc'), root('asdf', 'asdfrc'))
    dolink(home('.tool-versions'), root('asdf', 'tool-versions'))
    sh 'asdf plugin add ruby || true'
    sh 'asdf plugin add nodejs || true'
    sh 'asdf plugin add terraform || true'
    sh 'asdf plugin add golang || true'
    sh 'asdf plugin add packer || true'
    sh 'asdf plugin add rust || true'
    sh 'asdf install ruby'
    sh 'asdf install nodejs'
    sh 'asdf install terraform'
    sh 'asdf install packer'
    sh 'asdf install golang'
    sh 'asdf install rust'
  end

  task :update do
    puts 'Update: asdf plugins'.green
    sh 'asdf plugin update --all'
  end

  task :clean do
    sh "rm -f #{home('.tool-versions')}"
    clean_restore home('.asdfrc')
  end
end

task all: [:asdf]
task update: ['asdf:update']
task clean: ['asdf:clean']
