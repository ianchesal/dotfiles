#
# functions
#

function rpg {
  rg -p "$@" | less -R
}

function git_master_to_main() {
  git checkout master
  git pull
  git branch -m master main
  git push -u origin main
  git branch -u origin/main main
}

function heic2jpg() {
  # Preps HEIC images captured by my iPhone for posting on the interwebs
  # by converting them to jpg and stripping out all the exif location
  # data.
  for i in $*; do
    ext=$(echo $i:t:e | tr '[:upper:]' '[:lower:]')
    jpgfile="$i:r".jpg
    echo "Converting ${i} --> ${jpgfile}"
    mogrify -format jpg ${i}
    exiftool -all= ${jpgfile}
    if [[ -f "${jpgfile}_original" ]]; then
      rm "${jpgfile}_original"
    fi
  done
}

function dotenv() {
  # Loads a .env file from the cwd if one exists
  if [ -f ".env" ]; then
    set -o allexport
    source .env
    set +o allexport
  fi

}

function debug:config_files() {
  # Prints all the files that a program opens on startup
  # Helpful for figuring out where a program is reading
  # configuration from.
  strace -f "$1" 2>&1 | grep openat
}

# function crafting-old-sandboxes() {
#   JQ_QUERY=".[] | select((.spec.op_state.state == \"SUSPENDED\") and (.meta.updated_at <= \"$(date -v-27d +'%Y-%m-%d')\")) | {creator: .meta.owner.name, sandbox: .meta.name, updated_at: .meta.updated_at}"
#   cs sandbox list -o json | jq $JQ_QUERY
# }

function clean-nvim-logs() {
  rm -f ~/.local/state/nvim/log
  rm -f ~/.local/state/nvim/*.log
}

function dotfiles_update() {
  # Stop on any error
  set -e

  echo "\033[1;36m==> Updating your development environment...\033[0m"

  cd ~/src/dotfiles

  # Stash any local changes
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "\033[1;33m==> Stashing local changes...\033[0m"
    git stash push -m "dfu auto-stash"
    local STASHED=1
  fi

  # Update everything
  git pull
  rake update
  zinit update
  rake ohmyposh:update

  # Restore stashed changes if they exist
  if [[ -n "$STASHED" ]]; then
    echo "\033[1;33m==> Restoring local changes...\033[0m"
    git stash pop
  fi

  echo "\033[1;32m==> Update complete! Reloading shell...\033[0m"
  exec $SHELL
}
