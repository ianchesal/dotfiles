desc 'Install Atom dotfiles'
task atom: ['atom:all']

namespace :atom do
  CONFIG_FILES = %w(config.cson init.coffee keymap.cson snippets.cson styles.less).freeze

  task all: [:dir, :packages, :conf_files]

  task :dir do
    mkdir_if_needed home('.atom')
  end

  task :packages do
    File.readlines('atom/packages.list').each do |line|
      if File.directory?(home(".atom/packages/#{line.strip}"))
        sh "apm update #{line.strip}"
      else
        sh "apm install #{line.strip}"
      end
    end
  end

  task :conf_files do
    CONFIG_FILES.each do |f|
      dolink(home(".atom/#{f}"), root('atom', f))
    end
  end

  task :clean do
    File.readlines('atom/packages.list').each do |line|
      sh "apm uninstall #{line.strip}"
    end
    CONFIG_FILES.each do |f|
      clean_restore home(".atom/#{f}")
    end
  end
end

task all: [:atom]
task clean: ['atom:clean']
