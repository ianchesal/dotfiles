require 'pathname'

desc 'Install zsh dotfiles'
task zsh: ['zsh:ohmyzsh', 'zsh:rc', 'zsh:plugins']

namespace :zsh do

  task :ohmyzsh do
    puts "Cloning oh-my-zsh to ~/.oh-my-zsh..."
    `git clone --depth=1 --branch master https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh`
    puts "Clone PowerLevel10k to ~/.oh-my-zsh..."
    `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`
  end

  task :rc do
    dolink(home('.zshrc'), root('zsh', 'zshrc'))
    dolink(home('.zshenv'), root('zsh', 'zshenv'))
    dolink(home('.p10k.zsh'), root('zsh', 'p10k.zsh'))
  end

  task :plugins do
    mkdir_if_needed home('.oh-my-zsh/custom/plugins')
    Dir["zsh/plugins/*"].each do |pd|
      dolink(home(".oh-my-zsh/custom/plugins/#{pd.split('/')[-1]}"), root(pd))
    end
  end

  desc 'Update zsh and oh-my-zsh'
  task :update do
    puts 'Update: oh-my-zsh'.green
    Dir.chdir(File.expand_path('~/.oh-my-zsh')) do
      # puts "Skipping oh-my-zsh upgrade for now"
      sh 'sh ./tools/upgrade.sh' do |ok, res|
        # Do nothing, always successful
      end
      Dir.chdir('./custom/themes/powerlevel10k') do
        puts 'Update: PowerLevel10k'.green
        `git pull`
      end
    end
  end

  task :clean do
    clean_restore home('.zshrc')
    clean_restore home('.zshenv')
    if File.directory? home('.oh-my-zsh')
      `rm -rf ~/.oh-my-zsh`
    end
  end
end

task all: [:zsh]
task clean: ['zsh:clean']
task update: ['zsh:update']
