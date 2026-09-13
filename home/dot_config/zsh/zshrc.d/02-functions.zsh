#
# functions
#

# Add functions directory to fpath and autoload all functions
fpath=("${ZDOTDIR:-~/.config/zsh}/functions" $fpath)

# Autoload all functions in the functions directory
autoload -Uz "${ZDOTDIR:-~/.config/zsh}"/functions/*(:t)

function rpg {
  rg -p "$@" | less -R
}

# Convert HEIC images to JPG and strip EXIF data
function heic2jpg() {
  # Preps HEIC images captured by my iPhone for posting on the interwebs
  # by converting them to jpg and stripping out all the exif location
  # data.
  for i in "$@"; do
    ext=$(echo ${i:t:e} | tr '[:upper:]' '[:lower:]')
    jpgfile="${i:r}.jpg"
    echo "Converting ${i} --> ${jpgfile}"
    mogrify -format jpg "${i}"
    exiftool -all= "${jpgfile}"
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
  # workingTree is the repo root; sourceDir is <repo>/home. nvim/ lives at the
  # repo root, so pathspecs resolve against the repo, not the source dir.
  local REPO="$(chezmoi execute-template '{{ .chezmoi.workingTree }}')"
  local PINS=(nvim/pins.json nvim/nvim-pack-lock.json)

  # Guard: refuse to run with uncommitted or staged pin/lock changes, so an
  # update can't strand a half-committed pin state.
  if ! git -C "$REPO" diff --quiet -- $PINS 2>/dev/null || \
     ! git -C "$REPO" diff --cached --quiet -- $PINS 2>/dev/null; then
    echo "\033[1;31m==> nvim pins.json or nvim-pack-lock.json has uncommitted changes.\033[0m"
    return 1
  fi

  # Guard: refuse to run if the destination has drifted from what chezmoi
  # last applied (hand-edited configs that were never `chezmoi re-add`ed).
  # This must happen before `git pull` -- once the repo advances, `chezmoi
  # diff` conflates incoming repo changes with local drift and we lose the
  # ability to show a clean local-only diff. Column 1 of `chezmoi status` is
  # exactly "last written state vs actual state", i.e. local drift.
  local drifted=() line status_col path
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    status_col="${line:0:1}"
    [[ "$status_col" == " " ]] && continue
    drifted+=("${line:3}")
  done < <(chezmoi status --path-style absolute)

  if (( ${#drifted[@]} > 0 )); then
    echo "\033[1;33m==> Local changes found that aren't in your dotfiles repo yet:\033[0m"
    for path in "${drifted[@]}"; do
      echo "\033[1;33m  - $path\033[0m"
      chezmoi diff --no-pager "$path"
    done
    echo "\033[1;33m==> Review these and consider 'chezmoi re-add <path>' before rerunning dfu.\033[0m"
    return 1
  fi

  echo "\033[1;36m==> Updating your development environment...\033[0m"
  chezmoi git pull -- --autostash --rebase || return 1

  # The gate. `chezmoi diff` only prints; apply is what lands changes, so the
  # confirmation has to sit between them. Skip the prompt entirely when
  # there's nothing to apply.
  if [[ -z "$(chezmoi diff --no-pager)" ]]; then
    echo "\033[1;32m==> No dotfiles changes to apply.\033[0m"
  else
    chezmoi diff --no-pager
    read -q "REPLY?Apply these changes? [y/N] " || return 1
    echo
    chezmoi apply --error-on-conflict || return 1
  fi

  rake update
  zinit update

  # An update run moves the pins; commit them so every machine converges on the
  # same delayed-pin state.
  if ! git -C "$REPO" diff --quiet -- $PINS 2>/dev/null; then
    echo "\033[1;33m==> Neovim plugins were updated, committing...\033[0m"
    rake nvim:commit
  fi

  echo "\033[1;32m==> Update complete! Reloading shell...\033[0m"
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
  rm -rf "$XDG_RUNTIME_DIR/containers" "$XDG_RUNTIME_DIR/libpod/tmp" && \
    brew services restart podman && \
    sudo mount -o remount,shared / /
}

function grd() {
  # Navigate to git repository root
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ $? -eq 0 ]]; then
    cd "$git_root"
  else
    echo "Error: Not in a git repository" >&2
    return 1
  fi
}

function gco() {
  _fzf_git_each_ref --no-multi | xargs git checkout
}

function gcpi() {
  _fzf_git_hashes --no-multi | xargs git cherry-pick
}

function gsta() {
  _fzf_git_stashes --no-multi | xargs git stash apply
}

function gstd() {
  _fzf_git_stashes --no-multi | xargs git stash drop
}

function gstp() {
  _fzf_git_stashes --no-multi | xargs git stash pop
}

function gsts() {
  _fzf_git_stashes --no-multi | xargs git stash show -p
}
