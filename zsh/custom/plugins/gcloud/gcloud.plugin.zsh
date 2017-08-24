# zsh install: https://github.com/robbyrussell/oh-my-zsh/
# gcloud sdk install: https://cloud.google.com/sdk/
# gcloud zsh completion install: https://github.com/littleq0903/gcloud-zsh-completion
#
# Assumes the glcoud SDK is installed in ${HOME}
GCLOUD_SDK_LOCATION="${HOME}/google-cloud-sdk"

export PATH="${GCLOUD_SDK_LOCATION}/bin:$PATH"

# See: https://cloud.google.com/sdk/crypto
# Required to work with legacy p12 keyfiles
export CLOUDSDK_PYTHON_SITEPACKAGES=1

if [[ -a "${GCLOUD_SDK_LOCATION}/completion.zsh.inc" ]]; then
  source "${GCLOUD_SDK_LOCATION}/completion.zsh.inc"
fi