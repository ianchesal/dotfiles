# Requires: brew install autojump
# See: https://github.com/wting/autojump
if type brew >/dev/null; then
	[ -f "$(brew --prefix)/etc/profile.d/autojump.sh" ] && . "$(brew --prefix)/etc/profile.d/autojump.sh"
fi
