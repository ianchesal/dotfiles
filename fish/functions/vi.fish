function vi
  if type -q nvim
    nvim $argv
  else if type -q vim
    vim $argv
  else
    command vi $argv
  end
end
