function atom-update-packages
  cd ~/src/dotfiles; rake atom:packages
end

function atom-update-plugins
  =atom-update-packages
end
