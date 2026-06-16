# dotfiles/gcloud

Maintenance tasks for the Google Cloud CLI (`gcloud`). This directory holds no
dotfiles to symlink — it only provides a rake task that keeps a
self-managed gcloud SDK installation up to date.

## Notes

- The update task only runs against a self-managed SDK: it skips a
  system-installed `/usr/bin/gcloud` (that should be handled by the system
  package manager) and requires `CLOUDSDK_HOME` to point at an existing SDK
  directory.
- If no gcloud CLI is found, the task reports that and does nothing.

## Tasks

- `rake gcloud:update` — update gcloud command line components
