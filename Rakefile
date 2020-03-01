# frozen_string_literal: true

# rubocop:disable Style/Documentation, Style/SingleLineMethods, Layout/EmptyLineBetweenDefs

require 'fileutils'

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
end

def dolink(target, source)
  File.delete target if File.symlink? target # Nuke symlinks. We don't care about backing those up
  backup target if File.exist? target
  sh "ln -s #{source} #{target}"
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

desc 'Update everything that can be (safely) updated'
task update: ['update:submodules', 'update:ohmyzsh', 'update:vundle']

namespace :update do
  desc 'Update oh-my-zsh'
  task :ohmyzsh do
    puts 'Update: oh-my-zsh'.green
    Dir.chdir(File.expand_path('~/.oh-my-zsh')) do
      sh 'sh ./tools/upgrade.sh'
    end
  end

  desc 'Update vim Vundle plugins'
  task :vundle do
    puts 'Update: Vundle plugins'.green
    sh 'sh ./vim/update-plugins.sh'
  end

  desc 'Update all the git submodules in this repository'
  task :submodules do
    puts 'Update: git submodules'.green
    sh 'git pull --recurse-submodules'
  end

  desc 'Update Homebrew'
  task :homebrew do
    puts 'Update: Homebrew'.green
    sh 'brew upgrade'
  end
end

desc 'Install all dotfiles (are you really sure you want to do this?)'
task all: []

desc 'Remove my customizations and restore system default dotfiles'
task clean: []

Dir.glob('*/*.rake').each { |r| load r }

# rubocop:enable Style/Documentation, Style/SingleLineMethods, Layout/EmptyLineBetweenDefs
