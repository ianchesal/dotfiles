require 'fileutils'

def dolink(target, source)
  backup target if File.exist? target
  system "ln -s #{source} #{target}"
  puts "Linked #{source} -> #{target}"
end

def clean_restore(target)
  return unless File.symlink? target
  File.delete target
  last_backup = find_backup target
  if File.exists? last_backup
    File.rename last_backup, target
    puts "Restored backup #{last_backup} -> #{target}"
  end
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
  system "rake -T"
end

desc "Install all dotfiles (are you really sure you want to do this?)"
task :all => [:bash, :zsh, :vim, :ruby, :curl, :git, :screen, :irssi]

desc "Remove my customizations and restore system default dotfiles"
task :clean => [
  'bash:clean',
  'zsh:clean',
  'vim:clean',
  'ruby:clean',
  'curl:clean',
  'git:clean',
  'screen:clean',
  'irssi:clean',
  'tmux:clean'
]

desc "Install vim dotfiles"
task :vim => ['vim:all']
task :vim do
  puts "Now run:\n\n"
  puts "\tbrew uninstall vim; rvm system; brew install vim"
  puts "\tvim +PluginInstall +qall"
  puts "\tcd ~/.vim/bundle/YouCompleteMe; ./install.sh"
  puts "\nto complete the installation."
end

namespace :vim do
  task :all => [:rc, :dir]

  task :rc do |t|
    dolink(home('.vimrc'), root('vim', 'vimrc'))
  end

  task :dir do |t|
    mkdir_if_needed home('.vim')
  end

  task :clean do |t|
    system "rm -rf #{home('.vim')}/*"
    clean_restore home('.vimrc')
  end
end

desc "Install git dotfiles"
task :git => ['git:all']

namespace :git do
  task :all => [:gitconfig, :gitignore, :gittemplate]

  task :gitconfig do |t|
    dolink(home('.gitconfig'), root('git', 'gitconfig'))
  end

  task :gitignore do |t|
    dolink(home('.gitignore'), root('git', 'gitignore'))
  end

  task :gittemplate do |t|
    mkdir_if_needed home('.git_template')
  end

  task :clean do |t|
    clean_restore home('.gitignore')
    clean_restore home('.gitconfig')
  end
end

desc "Install all Ruby-related dotfiles (gem, rubocop, etc.)"
task :ruby => ['ruby:all']

namespace :ruby do
  task :all => [:gemrc, :rubocop]

  task :gemrc => [:gemdir] do |t|
    dolink(home('.gemrc'), root('gem', 'gemrc'))
  end

  task :gemdir do |t|
    mkdir_if_needed home('.gem')
  end

  task :rubocop do |t|
    dolink(home('.rubocop.yml'), root('rubocop', 'rubocop.yml'))
  end

  task :clean do |t|
    clean_restore home('.rubocop.yml')
    clean_restore home('.gemrc')
  end
end

desc "Install curl dotfiles"
task :curl => ['curl:rc']

namespace :curl do
  task :rc do |t|
    dolink(home('.curlrc'), root('curl', 'curlrc'))
  end

  task :clean do |t|
    clean_restore home('.curlrc')
  end
end

desc "Install bash dotfiles"
task :bash => ['bash:all']

namespace :bash do
  task :all => [:rc, :inputrc, :profile]

  task :rc do |t|
    dolink(home('.bashrc'), root('bash', 'bashrc'))
  end

  task :inputrc do |t|
    dolink(home('.inputrc'), root('bash', 'inputrc'))
  end

  task :profile do |t|
    dolink(home('.bash_profile'), root('bash', 'bash_profile'))
  end

  task :clean do |t|
    clean_restore home('.bash_profile')
    clean_restore home('.inputrc')
    clean_restore home('.bashrc')
  end
end

desc "Install zsh dotfiles"
task :zsh => ['zsh:rc']

namespace :zsh do
  task :rc do |t|
    dolink(home('.zshrc'), root('zsh', 'zshrc'))
    dolink(home('.zshenv'), root('zsh', 'zshenv'))
  end

  task :clean do |t|
    clean_restore home('.zshrc')
    clean_restore home('.zshenv')
  end
end

desc "Install tmux dotfiles"
task :tmux => ['tmux:conf']

namespace :tmux do
  task :conf do |t|
    dolink(home('.tmux.conf'), root('tmux', 'tmux.conf'))
  end

  task :clean do |t|
    clean_restore home('.tmux.conf')
  end
end

desc "Install screen dotfiles"
task :screen => ['screen:rc']

namespace :screen do
  task :rc do |t|
    dolink(home('.screenrc'), root('screen', 'screenrc'))
  end

  task :clean do |t|
    clean_restore home('.screenrc')
  end
end

desc "Install irssi dotfiles"
task :irssi => ['irssi:all']

namespace :irssi do
  task :all do |t|
    dolink(home('.irssi'), root('irssi'))
  end

  task :clean do |t|
    clean_restore home('.irssi')
  end
end

desc "Install emacs dotfiles"
task :emacs => ['emacs:all']

namespace :emacs do
  task :all do |t|
    dolink(home('.spacemacs'), root('emacs', 'spacemacs'))
  end

  task :clean do |t|
    clean_restore home('.spacemacs')
  end
end
