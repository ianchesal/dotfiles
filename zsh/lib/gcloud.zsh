# Required for gcloud SDK to work in my environment
# because I don't have python2 in the path any more.
# This was set up with:
#     pyenv install 2.7.16
#     pyenv virtualenv 2.7.16 gcloud-sdk
export CLOUDSDK_PYTHON=~/.pyenv/versions/gcloud-sdk/bin/python2
# See: https://cloud.google.com/sdk/crypto
# Required to work with legacy p12 keyfiles
export CLOUDSDK_PYTHON_SITEPACKAGES=1
