desc 'Install Python and related dependencies'
task python: ['python:all']

PYTHON_VERSION = '3.8.3'

namespace :python do
  task all: [:install, :activate, :rc, :update]

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
    sh "pyenv global #{PYTHON_VERSION}"
  end

  task :rc do
    dolink(home('.pylintrc'), root('python', 'pylintrc'))
  end


  desc 'Update Python packages'
  task update: [:activate] do
    puts 'Update: Python and tools'.green
    sh 'pip install --upgrade pip'
    sh 'pip install --upgrade pipenv'
    sh 'pip install --upgrade pylint'
  end

  task :clean do
    clean_restore home('.pylintrc')
    puts 'No-op'
  end
end

task all: [:python]
task clean: ['python:clean']
task update: ['python:update']
