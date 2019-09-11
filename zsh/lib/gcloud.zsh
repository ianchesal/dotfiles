# Look for the GCloud installation
if [[  -d "${HOME}/google-cloud-sdk" ]]; then
  export CLOUD_SDK_LOCATION="${HOME}/google-cloud-sdk"
elif [[ -d "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]]; then
  export CLOUD_SDK_LOCATION="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
elif [[ -d "/usr/share/google-cloud-sdk" ]]; then
  export CLOUD_SDK_LOCATION="/usr/share/google-cloud-sdk"
elif [[ -d "/snap/google-cloud-sdk/current" ]]; then
  export CLOUD_SDK_LOCATION="/snap/google-cloud-sdk/current"
fi


if (( ${+CLOUD_SDK_LOCATION} )); then
  if ! type "gcloud" > /dev/null; then
    # Only source this if GCloud isn't already on the path
    source "${CLOUD_SDK_LOCATION}/path.zsh.inc"
  fi
  source "${CLOUD_SDK_LOCATION}/completion.zsh.inc"
fi

# Required for gcloud SDK to work in my environment
# because I don't have python2 in the path any more.
# This was set up with:
#     pyenv install 2.7.16
#     pyenv virtualenv 2.7.16 gcloud-sdk
export CLOUDSDK_PYTHON=~/.pyenv/versions/gcloud-sdk/bin/python2
# See: https://cloud.google.com/sdk/crypto
# Required to work with legacy p12 keyfiles
export CLOUDSDK_PYTHON_SITEPACKAGES=1
