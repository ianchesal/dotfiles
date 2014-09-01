export JAVA_HOME="$(/usr/libexec/java_home)"

export EC2_PRIVATE_KEY="$(/bin/ls "$HOME"/.aws/certs/*-pk.pem | /usr/bin/head -1)"
export EC2_CERT="$(/bin/ls "$HOME"/.aws/certs/*-cert.pem | /usr/bin/head -1)"
export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.7.1.0/libexec"

[[ -s "$HOME/.aws/keys.zsh" ]] && source "$HOME/.aws/keys.zsh"

export COPYFILE_DISABLE=true
