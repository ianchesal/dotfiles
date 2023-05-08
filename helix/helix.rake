desc 'Install helix editor configuration'
task helix: ['helix:binary', 'helix:conf']

namespace :helix do
  task :binary do
    Dir.chdir(File.expand_path('~/src')) do
      sh 'git clone https://github.com/helix-editor/helix' unless File.directory?('helix')
      Dir.chdir('helix') do
        sh 'git pull'
        sh 'cargo install --path helix-term --locked'
      end
    end
  end

  task update: 'lsp:update' do
    Dir.chdir(File.expand_path('~/src')) do
      sh 'git clone https://github.com/helix-editor/helix' unless File.directory?('helix')
      Dir.chdir('helix') do
        sh 'git pull'
        sh 'cargo install --path helix-term --locked'
      end
    end
  end

  task :conf do
    mkdir_if_needed home('.config')
    dolink(home('.config/helix'), root('helix'))
  end

  task :clean do
    sh "rm -f #{home('.config/helix')}"
    sh "rm -f #{home('.cache/helix')}"
  end
end

# task all: [:helix]
# task update: ['helix:update']
# task clean: ['helix:clean']
