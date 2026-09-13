PYTHON_VERSION = '3.11.4'.freeze

namespace :python do
  desc 'Install Python and dependencies'
  task :install do
    # Too many ways to install pyenv and it really depends on the OS
    # so for now I'm just enforcing it exists and leaving install as
    # a manual step if it doesn't exist.
    abort 'Missing pyenv -- please install it!' unless which('pyenv')
    puts "Installing Python #{PYTHON_VERSION} with pyenv".green
    sh "pyenv install --skip-existing #{PYTHON_VERSION}"
  end

  task :activate do
    puts "Activating Python #{PYTHON_VERSION}".green
    sh 'pyenv rehash'
    sh "pyenv global #{PYTHON_VERSION}"
  end

  desc 'Update Python packages'
  task update: [:activate] do
    if which('pip')
      puts 'Update: Python and tools'.green
      sh 'pip install --upgrade pip'
      sh 'pip install --upgrade pipenv'
      sh 'pip install --upgrade pylint'
      sh 'pyenv rehash'
    else
      puts 'Skipping -- no pip found'.yellow
    end
  end
end

# task update: ['python:update']
