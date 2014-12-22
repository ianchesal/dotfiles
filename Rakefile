require 'fileutils'

def dolink(target, source)
  backup target if File.exist? target
  system("ln -s #{source} #{target}")
  puts "Linked #{source} -> #{target}"
end

def backup(target)
  index = 0
  index += 1 while File.exist? target + ".#{index}"
  File.rename target, target + ".#{index}"
  puts "Renamed existing file #{target} -> #{target}.#{index}"
end

def root
  File.dirname(__FILE__)
end

def mkdir_if_needed(path)
  FileUtils.mkdir_p path unless File.directory? path
end

task :default do
  system "rake -T"
end

desc "Install vim dotfiles"
task :vim => [:vimrc, :vimdir]
task :vim do
  puts "Now run:\n\n"
  puts "\tbrew uninstall vim; rvm system; brew install vim"
  puts "\tvim +PluginInstall +qall"
  puts "\tcd ~/.vim/bundle/YouCompleteMe; ./install.sh"
  puts "\nto complete the installation."
end

task :vimrc do |t|
  dolink(File.join(ENV['HOME'], '.vimrc'), File.join(root, 'vim', 'vimrc'))
end

task :vimdir do |t|
  mkdir_if_needed File.expand_path '~/.vim'
end

desc "Install git dotfiles"
task :git => [:gitconfig, :gitignore, :gittemplate]

task :gitconfig do |t|
  dolink(File.join(ENV['HOME'], '.gitconfig'), File.join(root, 'git', 'gitconfig'))
end

task :gitignore do |t|
  dolink(File.join(ENV['HOME'], '.gitignore'), File.join(root, 'git', 'gitignore'))
end

task :gittemplate do |t|
  mkdir_if_needed File.expand_path '~/.git_template'
end

desc "Install all Ruby-related dotfiles (gem, rubocop, etc.)"
task :ruby => [:gem, :rubocop]

task :gem => [:gemrc]

task :gemrc do |t|
  mkdir_if_needed File.expand_path '~/.gem'
  dolink(File.join(ENV['HOME'], '.gemrc'), File.join(root, 'gem', 'gemrc'))
end

task :rubocop do |t|
  dolink(File.join(ENV['HOME'], '.rubocop.yml'), File.join(root, 'rubocop', 'rubocop.yml'))
end

desc "Install curl dotfiles"
task :curl do |t|
  dolink(File.join(ENV['HOME'], '.curlrc'), File.join(root, 'curl', 'curlrc'))
end

desc "Install bash dotfiles"
task :bash => [:bashrc, :bash_profile]

task :bashrc do |t|
  dolink(File.join(ENV['HOME'], '.bashrc'), File.join(root, 'bash', 'bashrc'))
end

task :bash_profile do |t|
  dolink(File.join(ENV['HOME'], '.bash_profile'), File.join(root, 'bash', 'bash_profile'))
end

desc "Install zsh dotfiles"
task :zsh => [:zshrc]

task :zshrc do |t|
  dolink(File.join(ENV['HOME'], '.zshrc'), File.join(root, 'zsh', 'zshrc'))
end

