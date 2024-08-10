# GCLOUD CONFIG
# Required for gcloud SDK to work in my environment
# because I don't have python2 in the path any more.
# This was set up with:
#     pyenv install 2.7.16
#     pyenv virtualenv 2.7.16 gcloud-sdk
# if [ "$(uname 2> /dev/null)" != "Linux" ]; then
#   # Only need this on macOS
#   export CLOUDSDK_PYTHON=~/.pyenv/versions/gcloud-sdk/bin/python3
# fi
# See: https://cloud.google.com/sdk/crypto
# Required to work with legacy p12 keyfiles
# export CLOUDSDK_PYTHON_SITEPACKAGES=1
# See: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export CLOUDSDK_HOME="$HOME/src/google-cloud-sdk"

if (( ${+CLOUDSDK_HOME} )); then
  if (( ! $+commands[gcloud] )); then
    # Only source this if GCloud isn't already on the path
    if [[ -f "${CLOUDSDK_HOME}/path.zsh.inc" ]]; then
      source "${CLOUDSDK_HOME}/path.zsh.inc"
    fi
  fi
  source "${CLOUDSDK_HOME}/completion.zsh.inc"
  export CLOUDSDK_HOME
fi
