function git
  if test -x /usr/local/bin/stripe-git
    command stripe-git $argv
  else
    command git $argv
  end
end
