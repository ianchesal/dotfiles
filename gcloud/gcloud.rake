desc 'Keep Google Cloud CLI stuff up-to-date'

namespace :gcloud do
  desc 'Update gcloud commmand line components'
  task :update do
    if File.directory?(ENV.fetch('CLOUDSDK_HOME', ''))
      puts 'Update: gcloud components'.green
      sh 'gcloud components update --quiet'
      # sh 'type gcloud >/dev/null && $(gcloud info --format="value(basic.python_location)") -m pip install numpy'
    else
      puts 'No updates to gcloud components performance -- no gcloud CLI found'.red
    end
  end
end

task update: ['gcloud:update']
