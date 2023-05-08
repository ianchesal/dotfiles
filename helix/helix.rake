desc 'Install helix editor configuration'
task helix: ['helix:conf']

namespace :helix do
  task :conf do
    mkdir_if_needed home('.config')
    dolink(home('.config/helix'), root('helix'))
  end

  task :lsp do
    sh 'npm i -g bash-language-server'
    sh 'npm install -g dockerfile-language-server-nodejs'
    sh 'npm i -g vscode-langservers-extracted'
    sh 'npm install --location=global pyright'
    sh 'cargo install taplo-cli --locked --features lsp'
  end

  task :clean do
    sh "rm -f #{home('.config/helix')}"
    sh "rm -f #{home('.cache/helix')}"
  end
end

task all: [:helix]
task clean: ['helix:clean']
