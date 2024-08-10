desc 'Keep Google Cloud CLI stuff up-to-date'

namespace :gcloud do
  desc 'Update gcloud commmand line components'
  task :update do
    puts 'Update: gcloud components'.green
    sh 'type gcloud >/dev/null && gcloud components update --quiet'
    # sh 'type gcloud >/dev/null && $(gcloud info --format="value(basic.python_location)") -m pip install numpy'
  end
end

task update: ['gcloud:update']
