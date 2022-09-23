command -v terraform &> /dev/null && FOUND_TERRAFORM=1 || FOUND_TERRAFORM=0

if [[ $FOUND_TERRAFORM -eq 1 ]]; then
  complete -o nospace -C $(which terraform) terraform
fi
