desc 'Install zsh dotfiles'
task zsh: ['zsh:ohmyzsh', 'zsh:rc']

namespace :zsh do
  task :ohmyzsh do
    unless File.directory? home('.oh-my-zsh') do
      puts "Cloning oh-my-zsh to ~/.oh-my-zsh..."
      `git clone --depth=1 --branch master https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh`
    end
    end
  end


  task :rc do
    dolink(home('.zshrc'), root('zsh', 'zshrc'))
    dolink(home('.zshenv'), root('zsh', 'zshenv'))
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
