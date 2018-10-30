function git
  if type -q hub
    command hub $argv
  else
    if test -x /usr/local/bin/stripe-git
      command stripe-git $argv
    else
     command git $argv
    end
  end
end
