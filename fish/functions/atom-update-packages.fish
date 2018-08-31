function atom-update-packages
  cd ~/code/dotfiles; rake atom:packages
end

function atom-update-plugins
  =atom-update-packages
end
