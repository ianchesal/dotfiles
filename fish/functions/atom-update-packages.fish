function atom-update-packages
  cd ~/Development/dotfiles; rake atom:packages
end

function atom-update-plugins
  =atom-update-packages
end
