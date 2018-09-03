function ssh
  if test -x ~/stripe/space-commander/bin/sc-ssh-wrapper
    command sc-ssh-wrapper $argv
  else
    command ssh $argv
  end
end
