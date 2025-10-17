desc 'Keep Google Cloud CLI stuff up-to-date'

namespace :gcloud do
  desc 'Update gcloud commmand line components'
  task :update do
    gcloud_path = `which gcloud 2>/dev/null`.strip

    if gcloud_path == '/usr/bin/gcloud'
      puts 'Skipping gcloud components update -- system-installed gcloud should be managed by system package manager'.yellow
    elsif File.directory?(ENV.fetch('CLOUDSDK_HOME', ''))
      puts 'Update: gcloud components'.green
      sh 'gcloud components update --quiet'
      # sh 'type gcloud >/dev/null && $(gcloud info --format="value(basic.python_location)") -m pip install numpy'
    else
      puts 'No updates to gcloud components performed -- no gcloud CLI found'.red
    end
  end
end

task update: ['gcloud:update']
