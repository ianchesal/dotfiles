desc 'Install serena'
task serena: ['serena:all']

namespace :serena do
  task all: [:install]

  task :install do
    mkdir_if_needed root('serena/.serena')
    unless Dir.exist?(root('serena/.serena/.git'))
      puts 'Cloning git@github.com:oraios/serena.git...'
      sh "git clone git@github.com:oraios/serena.git #{root('serena/.serena')}"
    end
    unless File.exist?(root('serena/.serena/serena_config.yml'))
      puts 'Installing serena_config.yml...'
      sh "cp #{root('serena/serena_config.yml')} #{root('serena/.serena/serena_config.yml')}"
    end
    dolink(home('.serena'), root('serena'))
    puts "Serena installed at: #{root('serena/.serena')}"
  end

  task :update do
    if Dir.exist?(root('serena/.serena/.git'))
      puts 'Update: serena'.green
      chdir root('serena/.serena') do
        sh 'git pull'
      end
    end
  end

  task :clean do
    sh "rm -rf #{root('serena/.serena')}"
  end
end

# task all: [:serena]
task update: ['serena:update']
task clean: ['serena:clean']
