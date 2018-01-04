# Assumes the glcoud SDK is installed in ${HOME}
GCLOUD_SDK_LOCATION="${HOME}/google-cloud-sdk"
path+=($GCLOUD_SDK_LOCATION/bin)
export PATH

# See: https://cloud.google.com/sdk/crypto
# Required to work with legacy p12 keyfiles
export CLOUDSDK_PYTHON_SITEPACKAGES=1

if [[ -a "${GCLOUD_SDK_LOCATION}/completion.zsh.inc" ]]; then
  source "${GCLOUD_SDK_LOCATION}/completion.zsh.inc"
fi
