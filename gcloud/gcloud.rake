desc 'Keep Google Cloud CLI stuff up-to-date'

namespace :gcloud do
  desc 'Update gcloud commmand line components'
  task :update do
    if File.file?('/opt/homebrew/bin/gcloud') || File.file?('/usr/local/bin/gcloud')
      puts 'Update: gcloud components'.green
      sh 'gcloud components update --quiet'
      sh '$(gcloud info --format="value(basic.python_location)") -m pip install numpy'
    else
      puts 'No updates to gcloud components performance -- no gcloud CLI found'.red
    end
  end
end

task update: ['gcloud:update']
