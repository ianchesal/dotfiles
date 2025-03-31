# frozen_string_literal: true

# rubocop:disable Style/Documentation, Style/SingleLineMethods

require 'fileutils'

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def yellow;         "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
  def bold;           "\e[1m#{self}\e[0m" end
end

module OS
  def self.windows?
    !(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  end

  def self.mac?
    !(/darwin/ =~ RUBY_PLATFORM).nil?
  end

  def self.unix?
    !OS.windows?
  end

  def self.linux?
    OS.unix? and !OS.mac?
  end

  def self.jruby?
    RUBY_ENGINE == 'jruby'
  end
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
  target + ".#{index - 1}"
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

def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

task :default do
  system 'rake -T'
end

desc 'Update everything that can be (safely) updated'
task update: []

desc 'Install all dotfiles (are you really sure you want to do this?)'
task all: []

desc 'Remove my customizations and restore system default dotfiles'
task clean: []

Dir.glob('*/*.rake').each { |r| load r }

# rubocop:enable Style/Documentation, Style/SingleLineMethods
