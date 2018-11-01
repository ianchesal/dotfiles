require 'fileutils'

def dolink(target, source)
  File.delete target if File.symlink? target # Nuke symlinks. We don't care about backing those up
  backup target if File.exist? target
  system "ln -s #{source} #{target}"
  puts "Linked #{source} -> #{target}"
end

def clean_restore(target)
  return unless File.symlink? target
  File.delete target
  last_backup = find_backup target
  return unless File.exist? last_backup
  File.rename last_backup, target
  puts "Restored backup #{last_backup} -> #{target}"
end

def find_backup(target)
  index = 0
  index += 1 while File.exist? target + ".#{index}"
  target + ".#{index-1}"
end

def backup(target)
  index = 0
  index += 1 while File.exist? target + ".#{index}"
  File.rename target, target + ".#{index}"
  puts "Renamed existing file #{target} -> #{target}.#{index}"
end

def root(*args)
  File.join(File.dirname(__FILE__), args)
end

def home(*args)
  File.join(File.expand_path('~'), args)
end

def mkdir_if_needed(path)
  FileUtils.mkdir_p path unless File.directory? path
end

task :default do
  system 'rake -T'
end

desc 'Install all dotfiles (are you really sure you want to do this?)'
task all: [:bash, :zsh, :vim, :ruby, :curl, :git, :screen, :irssi, :atom, :fish]

desc 'Remove my customizations and restore system default dotfiles'
task clean: [
  'bash:clean',
  'zsh:clean',
  'vim:clean',
  'ruby:clean',
  'curl:clean',
  'git:clean',
  'screen:clean',
  'irssi:clean',
  'tmux:clean',
  'atom:clean',
  'octave:clean',
  'fish:clean'
]

desc 'Install vim and neovim dotfiles'
task vim: ['vim:all']
task :vim do
  puts "Now run:\n\n"
  puts "\tbrew uninstall vim; rvm system; brew install vim"
  puts "\tvim +PluginInstall +qall"
  puts "\tcd ~/.vim/bundle/YouCompleteMe; ./install.sh"
  puts "\nto complete the installation."
end

namespace :vim do
  task all: [:dir, :rc]

  task :rc do
    dolink(home('.vimrc'), root('vim', 'vimrc'))
    dolink(home('.config/nvim/init.vim'), root('vim', 'vimrc'))
  end

  task :dir do
    mkdir_if_needed home('.config')
    mkdir_if_needed home('.vim')
    dolink('~/.config/nvim', '~/.vim')
  end

  task :clean do
    system "rm -rf #{home('.vim')}/*"
    clean_restore home('.vimrc')
  end
end

desc 'Install git dotfiles'
task git: ['git:all']

namespace :git do
  task all: [:gitconfig, :gitignore, :gittemplate]

  task :gitconfig do
    dolink(home('.gitconfig'), root('git', 'gitconfig'))
  end

  task :gitignore do
    dolink(home('.gitignore'), root('git', 'gitignore'))
  end

  task :gittemplate do
    mkdir_if_needed home('.git_template')
  end

  task :clean do
    clean_restore home('.gitignore')
    clean_restore home('.gitconfig')
  end
end

desc 'Install all Ruby-related dotfiles (gem, rubocop, etc.)'
task ruby: ['ruby:all']

namespace :ruby do
  task all: [:gemrc, :rubocop]

  task gemrc: [:gemdir] do
    dolink(home('.gemrc'), root('gem', 'gemrc'))
  end

  task :gemdir do
    mkdir_if_needed home('.gem')
  end

  task :rubocop do
    dolink(home('.rubocop.yml'), root('rubocop', 'rubocop.yml'))
  end

  task :clean do
    clean_restore home('.rubocop.yml')
    clean_restore home('.gemrc')
  end
end

desc 'Install tags dotfiles'
task ctags: ['ctags:rc']

namespace :ctags do
  task :rc do
    dolink(home('.ctags'), root('ctags', 'ctags'))
  end

  task :clean do
    clean_restore home('.ctags')
  end
end

desc 'Install curl dotfiles'
task curl: ['curl:rc']

namespace :curl do
  task :rc do
    dolink(home('.curlrc'), root('curl', 'curlrc'))
  end

  task :clean do
    clean_restore home('.curlrc')
  end
end

desc 'Install bash dotfiles'
task bash: ['bash:all']

namespace :bash do
  task all: [:rc, :inputrc, :profile]

  task :rc do
    dolink(home('.bashrc'), root('bash', 'bashrc'))
  end

  task :inputrc do
    dolink(home('.inputrc'), root('bash', 'inputrc'))
  end

  task :profile do
    dolink(home('.bash_profile'), root('bash', 'bash_profile'))
  end

  task :clean do
    clean_restore home('.bash_profile')
    clean_restore home('.inputrc')
    clean_restore home('.bashrc')
  end
end

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

desc 'Install go-jira dotfiles'
task gojira: ['gojira:config']

namespace :gojira do
  task :config do
    mkdir_if_needed home('.jira.d')
    dolink(home('.jira.d/config.yml'), root('gojira', 'config.yml'))
  end

  task :clean do
    clean_restore home(".jira.d/config.yml")
  end
end

desc 'Install zsh dotfiles'
task zsh: ['zsh:rc']

namespace :zsh do
  task :rc do
    dolink(home('.zshrc'), root('zsh', 'zshrc'))
    dolink(home('.zshenv'), root('zsh', 'zshenv'))
  end

  task :clean do
    clean_restore home('.zshrc')
    clean_restore home('.zshenv')
  end
end

desc 'Install tmux dotfiles'
task tmux: ['tmux:conf']

namespace :tmux do
  task :conf do
    dolink(home('.tmux.conf'), root('tmux', 'tmux.conf'))
  end

  task :clean do
    clean_restore home('.tmux.conf')
  end
end

desc 'Install screen dotfiles'
task screen: ['screen:rc']

namespace :screen do
  task :rc do
    dolink(home('.screenrc'), root('screen', 'screenrc'))
  end

  task :clean do
    clean_restore home('.screenrc')
  end
end

desc 'Install irssi dotfiles'
task irssi: ['irssi:all']

namespace :irssi do
  task :all do
    dolink(home('.irssi'), root('irssi'))
  end

  task :clean do
    clean_restore home('.irssi')
  end
end

desc 'Install emacs dotfiles'
task emacs: ['emacs:all']

namespace :emacs do
  task :all do
    dolink(home('.spacemacs'), root('emacs', 'spacemacs'))
  end

  task :clean do
    clean_restore home('.spacemacs')
  end
end

desc 'Install octave dotfiles'
task octave: ['octave:all']

namespace :octave do
  task :all do
    dolink(home('.octaverc'), root('octave', 'octaverc'))
  end

  task :clean do
    clean_restore home('.octaverc')
  end
end

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

namespace :rubocop do
  RUBOCOP = 'rubocop --display-cop-names --color'.freeze
  FILES_TO_CHECK = %w(Rakefile).freeze

  desc 'Run Rubocop checks'
  task :check do
    system("#{RUBOCOP} " + FILES_TO_CHECK.join(' '))
  end

  desc 'Auto-correct Rubocop failures'
  task :auto_correct do
    system("#{RUBOCOP} --auto-correct " + FILES_TO_CHECK.join(' '))
  end
end
