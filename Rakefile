# frozen_string_literal: true

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
task all: []

desc 'Remove my customizations and restore system default dotfiles'
task clean: []

Dir.glob('*/*.rake').each { |r| load r }
