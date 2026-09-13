# frozen_string_literal: true

# rubocop:disable Style/Documentation, Style/SingleLineMethods

require 'fileutils'

class String
  def black; "\e[30m#{self}\e[0m" end
  def red; "\e[31m#{self}\e[0m" end
  def green; "\e[32m#{self}\e[0m" end
  def brown; "\e[33m#{self}\e[0m" end
  def yellow; "\e[33m#{self}\e[0m" end
  def blue; "\e[34m#{self}\e[0m" end
  def magenta; "\e[35m#{self}\e[0m" end
  def cyan; "\e[36m#{self}\e[0m" end
  def gray; "\e[37m#{self}\e[0m" end
  def bold; "\e[1m#{self}\e[0m" end
end

# Anchored to this Rakefile's own directory and expanded, so every path a task
# builds is absolute and independent of the cwd rake was invoked from.
def root(*args)
  File.expand_path(File.join(File.dirname(__FILE__), args))
end

def home(*args)
  File.join(File.expand_path('~'), args)
end

# ~/.work_machine marks this box as a work machine. A file test can't depend on
# the environment, so it reads the same from rake, a tmux popup, or cron -- which
# the WORK_MACHINE env var it replaced could not (see zsh/zshrc.d/machine.zsh).
def work_machine?
  File.exist? home('.work_machine')
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

# root() rather than a bare relative glob: rake only chdirs to the Rakefile's
# directory when it finds one by searching upwards, not when handed `-f <path>`,
# and a cwd-relative glob silently loaded zero task files in that case.
Dir.glob(root('*', '*.rake')).each { |r| load r }

# rubocop:enable Style/Documentation, Style/SingleLineMethods
