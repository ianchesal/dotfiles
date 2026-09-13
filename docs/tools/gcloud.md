# gcloud

Maintenance task for the Google Cloud CLI (`gcloud`). There are no dotfiles to
deploy — just a recipe (`just/gcloud.just`) that keeps a self-managed gcloud SDK
installation up to date.

## Notes

- The update task only runs against a self-managed SDK: it skips a
  system-installed `/usr/bin/gcloud` (that should be handled by the system
  package manager) and requires `CLOUDSDK_HOME` to point at an existing SDK
  directory.
- If no gcloud CLI is found, the task reports that and does nothing.

## Tasks

- `just gcloud::update` — update gcloud command line components
