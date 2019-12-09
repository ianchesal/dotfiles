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

task all: [:octave]
task clean: ['octave:clean']
