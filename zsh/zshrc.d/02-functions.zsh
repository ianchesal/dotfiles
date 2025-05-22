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

function __my_sleep_spinner() {
  local seconds=${1:-60}
  local frames=('-' '\' '|' '/')
  local frame=0

  # Hide cursor
  tput civis

  # Display spinner for specified seconds
  for ((i=0; i<seconds; i++)); do
    printf "\r${frames[$frame]} Waiting: %d/%d seconds" $((i+1)) "$seconds"
    sleep 1
    frame=$(( (frame+1) % 4 ))
  done

  # Show cursor again and add newline
  tput cnorm
  printf "\n"
}

function dotfiles_update() {
  echo "\033[1;36m==> Updating your development environment...\033[0m" && \
  cd ~/src/dotfiles && \

  # Stash any local changes
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "\033[1;33m==> Stashing local changes...\033[0m" && \
    git stash push -u -m "dfu auto-stash" && \
    local STASHED=1
  fi && \

  # Update everything
  git pull && \
  rake update && \
  zinit update && \
  rake ohmyposh:update && \

  # Restore stashed changes if they exist
  if [[ -n "$STASHED" ]]; then
    echo "\033[1;33m==> Restoring local changes...\033[0m" && \
    git stash pop
  fi && \

  echo "\033[1;32m==> Update complete! Reloading shell...\033[0m" && \
  exec $SHELL
}

# Find a window in aerospace and focus it
function ff() {
  aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

function tn() {
  local session=${1:-main}
  tmux new-session -A -s "$session"
}

function ta() {
  if [[ -n "$1" ]]; then
    tn "$1"
  else
    # Check if there are any existing sessions
    if ! tmux list-sessions &>/dev/null; then
      echo "\033[1;33mNo existing tmux sessions found\033[0m"
      return 1
    fi
    
    # No argument, use fzf to select from existing sessions
    local session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)
    if [[ -n "$session" ]]; then
      tmux attach-session -d -t "$session"
    fi
  fi
}

function hb_update_node() {
  if [[ "$(hostname)" == "tranquility" ]]; then
    pushd ~/src/torrent-management/docker/
    sudo docker compose -f docker-compose.homebridge.yml exec homebridge hb-service update-node
    popd
  else
    echo "\033[1;31mThis command can only be run on tranquility\033[0m"
    return 1
  fi
}

function unfuck-podman-on-wsl() {
  # I have to do this after every Windows machine restart to
  # put rootless podman back in a useable state. Will figure
  # out why later. For now...
  if [[ -n "$TMUX" ]]; then
    echo "Error: This function cannot be run from within a tmux session"
    return 1
  fi
  rm -rf ~/.xdg/containers ~/.xdg/libpod/tmp && \
  brew services restart podman && \
  sudo mount -o remount,shared / /
}

function __ai_container_launcher() {
  if type podman >/dev/null; then
    LAUNCHER="podman run --userns=keep-id"
  else
    LAUNCHER="docker run"
  fi
  echo $LAUNCHER
}

function claude() {
  if [[ -x "${HOME}/.npm-global/bin/claude" ]]; then
    "${HOME}/.npm-global/bin/claude" "$@"
  else
    eval "$(__ai_container_launcher) --tty --interactive \
      -v ${HOME}/.claude:/home/codeuser/.claude:rw \
      -v $(pwd):/app:rw \
      claude-code $@"
  fi
}

function codex() {
  if [[ -x "${HOME}/.npm-global/bin/codex" ]]; then
    "${HOME}/.npm-global/bin/codex" "$@"
  else
    eval "$(__ai_container_launcher) --rm --tty --interactive -e OPENAI_API_KEY -v $(pwd):/app:rw openai-codex $@"
  fi
}
