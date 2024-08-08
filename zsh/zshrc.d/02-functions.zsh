#
# functions
#

# _has() {
#   # Returns whether the given command is executable or aliased.
#   return $(type $1 >/dev/null)
# }

# function git_master_to_main() {
#   git checkout master
#   git pull
#   git branch -m master main
#   git push -u origin main
#   git branch -u origin/main main
# }

# function debug:config_files() {
#   # Prints all the files that a program opens on startup
#   # Helpful for figuring out where a program is reading
#   # configuration from.
#   strace -f "$1" 2>&1 | grep openat
# }

# function crafting-old-sandboxes() {
#   JQ_QUERY=".[] | select((.spec.op_state.state == \"SUSPENDED\") and (.meta.updated_at <= \"$(date -v-27d +'%Y-%m-%d')\")) | {creator: .meta.owner.name, sandbox: .meta.name, updated_at: .meta.updated_at}"
#   cs sandbox list -o json | jq $JQ_QUERY
# }
