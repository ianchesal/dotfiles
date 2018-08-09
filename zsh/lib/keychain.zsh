# For keychain frontend to ssh-agent
# See: brew info keychain
if _has keychain && [ -f "~/.ssh/id_rsa" ]; then
  export SSH_KEY_PATH="~/.ssh/id_rsa"
  # funtoo keychain
  eval `keychain -q --eval ~/.ssh/id_rsa`
fi
