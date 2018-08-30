function ssh
  if test -x ~/stripe/space-commander/bin/sc-ssh-wrapper
    sc-ssh-wrapper $argv
  else
    ssh $argv
  end
end
