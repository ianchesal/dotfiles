desc 'Install all asdf dotfiles'
task asdf: ['asdf:all']

namespace :asdf do
  task all: [:asdf]

  # Depends on rust:install because ruby-build only compiles YJIT/ZJIT into Ruby when a
  # Rust toolchain is present at build time, and `rake all` would otherwise reach asdf first.
  task asdf: ['rust:install'] do
    dolink(home('.asdfrc'), root('asdf', 'asdfrc'))
    dolink(home('.tool-versions'), root('asdf', 'tool-versions'))
    sh 'asdf plugin add ruby || true'
    sh 'asdf plugin add nodejs || true'
    sh 'asdf plugin add golang || true'
    sh 'asdf install ruby'
    sh 'asdf install nodejs'
    sh 'asdf install golang'
  end

  task :update do
    puts 'Update: asdf'.green
    # This is no longer supported
    # sh 'asdf update'
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
