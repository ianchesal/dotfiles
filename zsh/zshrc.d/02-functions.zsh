#
# functions
#

function rpg {
  rg -p "$@" | less -R
}

# Lazy load git_master_to_main function (rarely used)
git_master_to_main() {
  unfunction git_master_to_main
  
  # Define the actual function
  git_master_to_main() {
    git checkout master
    git pull
    git branch -m master main
    git push -u origin main
    git branch -u origin/main main
  }
  
  # Call the actual function
  git_master_to_main "$@"
}

# Lazy load heic2jpg function (rarely used)
heic2jpg() {
  unfunction heic2jpg
  
  # Define the actual function
  heic2jpg() {
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
  
  # Call the actual function
  heic2jpg "$@"
}

function dotenv() {
  # Loads a .env file from the cwd if one exists
  if [ -f ".env" ]; then
    set -o allexport
    source .env
    set +o allexport
  fi

}

# Lazy load debug:config_files function (rarely used)
debug:config_files() {
  unfunction debug:config_files
  
  # Define the actual function
  debug:config_files() {
    # Prints all the files that a program opens on startup
    # Helpful for figuring out where a program is reading
    # configuration from.
    strace -f "$1" 2>&1 | grep openat
  }
  
  # Call the actual function
  debug:config_files "$@"
}

# function crafting-old-sandboxes() {
#   JQ_QUERY=".[] | select((.spec.op_state.state == \"SUSPENDED\") and (.meta.updated_at <= \"$(date -v-27d +'%Y-%m-%d')\")) | {creator: .meta.owner.name, sandbox: .meta.name, updated_at: .meta.updated_at}"
#   cs sandbox list -o json | jq $JQ_QUERY
# }

# Lazy load clean-nvim-logs function (rarely used)
clean-nvim-logs() {
  unfunction clean-nvim-logs
  
  # Define the actual function
  clean-nvim-logs() {
    rm -f ~/.local/state/nvim/log
    rm -f ~/.local/state/nvim/*.log
  }
  
  # Call the actual function
  clean-nvim-logs "$@"
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
    local target_dir="/home/ian/src/torrent-management/docker/"
    if [[ ! -d "$target_dir" ]]; then
      echo "\033[1;31mError: Directory $target_dir does not exist\033[0m"
      return 1
    fi

    if pushd "$target_dir" > /dev/null; then
      sudo docker compose -f docker-compose.homebridge.yml exec homebridge hb-service update-node
      popd > /dev/null
    else
      echo "\033[1;31mError: Failed to change to directory $target_dir\033[0m"
      return 1
    fi
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
  if (( $+commands[podman] )); then
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

function serena-install() {
  local serena_dir="${1:-${HOME}/src/oraios/serena}"
  local repo_url="git@github.com:oraios/serena.git"
  local config_file="serena_config.yml"
  
  echo "\033[1;36m==> Setting up Serena at: $serena_dir\033[0m"
  
  # Check and create directory if needed
  if [[ ! -d "$serena_dir" ]]; then
    echo "\033[1;33m==> Creating directory: $serena_dir\033[0m"
    if ! mkdir -p "$serena_dir"; then
      echo "\033[1;31mError: Failed to create directory $serena_dir\033[0m"
      return 1
    fi
  else
    echo "\033[1;32m✓\033[0m Directory $serena_dir already exists"
  fi
  
  # Change to the serena directory
  if ! pushd "$serena_dir" > /dev/null; then
    echo "\033[1;31mError: Failed to change to directory $serena_dir\033[0m"
    return 1
  fi
  
  # Check if git repo exists, if not clone it
  if [[ ! -d ".git" ]]; then
    echo "\033[1;33m==> Cloning Serena repository...\033[0m"
    if ! git clone "$repo_url" .; then
      echo "\033[1;31mError: Failed to clone repository $repo_url\033[0m"
      popd > /dev/null
      return 1
    fi
    echo "\033[1;32m✓\033[0m Repository cloned successfully"
  else
    # Check if it's the correct repository
    local current_origin=$(git remote get-url origin 2>/dev/null)
    if [[ "$current_origin" == "$repo_url" ]]; then
      echo "\033[1;32m✓\033[0m Git repository already exists and is correct"
    else
      echo "\033[1;33m==> Warning: Directory contains a different git repository\033[0m"
      echo "    Current origin: $current_origin"
      echo "    Expected: $repo_url"
    fi
  fi
  
  # Check and create config file if needed
  if [[ ! -f "$config_file" ]]; then
    echo "\033[1;33m==> Creating $config_file...\033[0m"
    cat > "$config_file" << 'EOF'
gui_log_window: false
web_dashboard: true
trace_lsp_communication: false
tool_timeout: 240

# MANAGED BY SERENA, KEEP AT THE BOTTOM OF THE YAML AND DON'T EDIT WITHOUT NEED
# The list of registered projects.
# To add a project, within a chat, simply ask Serena to "activate the project /path/to/project" or,
# if the project was previously added, "activate the project <project name>".
# By default, the project's name will be the name of the directory containing the project, but you may change it
# by editing the (auto-generated) project configuration file `/path/project/project/.serena/project.yml` file.
# If you want to maintain full control of the project configuration, create the project.yml file manually and then
# instruct Serena to activate the project by its path for first-time activation.
# NOTE: Make sure there are no name collisions in the names of registered projects.
projects:
- $serena_dir
EOF
    if [[ $? -eq 0 ]]; then
      echo "\033[1;32m✓\033[0m Configuration file created successfully"
    else
      echo "\033[1;31mError: Failed to create configuration file\033[0m"
      popd > /dev/null
      return 1
    fi
  else
    echo "\033[1;32m✓\033[0m Configuration file $config_file already exists"
  fi
  
  popd > /dev/null
  echo "\033[1;32m==> Serena setup complete!\033[0m"
  echo "\033[1;36mSerena is now ready at: $serena_dir\033[0m"
}
