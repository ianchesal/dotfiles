if [ "$(uname 2> /dev/null)" = "Darwin" ]; then

# For the 5.0.x Homebrew'ed zsh installation...
# unalias run-help
autoload run-help
HELPDIR=/usr/local/share/zsh/help

# Opt out of Homebrew analytics
export HOMEBREW_NO_ANALYTICS=1

# Cask options
HOMEBREW_CASK_OPTS="--appdir=~/Applications"

if _has fzf; then
# Install (one or multiple) selected application(s)
# using "brew search" as source input
# mnemonic [B]rew [I]nstall [P]lugin
bip() {
	local inst=$(brew search | fzf -m)

	if [[ $inst ]]; then
		for prog in $(echo $inst);
		do; brew install $prog; done;
	fi
}

# Update (one or multiple) selected application(s)
# mnemonic [B]rew [U]pdate [P]lugin
bup() {
	local upd=$(brew leaves | fzf -m)

	if [[ $upd ]]; then
		for prog in $(echo $upd);
		do; brew upgrade $prog; done;
	fi
}

# Delete (one or multiple) selected application(s)
# mnemonic [B]rew [C]lean [P]lugin (e.g. uninstall)
bcp() {
	local uninst=$(brew leaves | fzf -m)

	if [[ $uninst ]]; then
		for prog in $(echo $uninst);
		do; brew uninstall $prog; done;
	fi
}
fi

fi
