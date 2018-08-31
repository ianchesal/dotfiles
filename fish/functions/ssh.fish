function ssh
  if test -x ~/stripe/space-commander/bin/sc-ssh-wrapper
    sc-ssh-wrapper $argv
  else
    /usr/bin/ssh $argv
  end
end
