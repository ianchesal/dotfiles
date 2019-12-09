desc 'Install fish shell configuration'
task fish: ['fish:conf', 'fish:functions', 'fish:completions']

namespace :fish do
  task :conf do
    mkdir_if_needed home('.config/fish/conf.d')
    Dir["fish/conf.d/*.fish"].each do |cf|
      dolink(home(".config/#{cf}"), root(cf))
    end
    dolink(home('.config/fish/config.fish'), root('fish', 'config.fish'))
  end

  task :functions do
    mkdir_if_needed home('.config/fish/functions')
    Dir["fish/functions/*.fish"].each do |cf|
      dolink(home(".config/#{cf}"), root(cf))
    end
  end

  task :completions do
    mkdir_if_needed home('.config/fish/completions')
    Dir["fish/completions/*.fish"].each do |cf|
      dolink(home(".config/#{cf}"), root(cf))
    end
  end

  task :clean do
    Dir["fish/conf.d/*.fish"].each do |cf|
      clean_restore home(".config/#{cf}")
    end
    Dir["fish/functions/*.fish"].each do |cf|
      clean_restore home(".config/#{cf}")
    end
    Dir["fish/completions/*.fish"].each do |cf|
      clean_restore home(".config/#{cf}")
    end
    clean_restore home(".config/fish/config.fish")
  end
end

task all: [:fish]
task clean: ['fish:clean']
