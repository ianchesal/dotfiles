desc 'Install the Windows Terminal settings I like'
task winterm: ['winterm:settings']

settingsfile = '/mnt/c/Users/ianch/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'

namespace :winterm do
  task :settings do
    Dir.chdir('winterm') do
      sh "cp --force --verbose settings.json #{settingsfile}"
    end
  end
end
