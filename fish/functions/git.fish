function git
  if type -q hub
    command hub $argv
  else
    command git $argv
  end
end
