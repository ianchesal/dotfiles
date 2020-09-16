desc 'Install emacs dotfiles'
task emacs: ['emacs:all']

def batch_compile_prelude()
  sh 'emacs -batch -f batch-byte-compile ~/.emacs.d/core/*.el'
end

namespace :emacs do
  task all: [:install, :update]

  task :install do
    chdir home('.') do
      sh 'git clone git://github.com/bbatsov/prelude.git .emacs.d' unless File.directory? home('.emacs.d')
    end
    dolink(home('.emacs.d/personal/prelude-modules.el'), root('emacs', 'prelude-modules.el'))
  end

  task :update do
    if File.directory? home('.emacs.d')
      chdir home('.emacs.d') do
        sh 'git pull'
      end
    end
      batch_compile_prelude
  end
  
  task :clean do
    if File.directory? home('.emacs.d')
      chdir home('.') do
        sh 'rm -rf .emacs.d'
      end
    end
  end
end

task all: [:emacs]
task clean: ['emacs:clean']
