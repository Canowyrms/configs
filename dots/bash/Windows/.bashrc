# ----------------------
# Common
# ----------------------

case "$OSTYPE" in
	linux*) OS='linux' ;;
	msys*)  OS='windows' ;;
esac

export OS


# ----------------------
# shopts
# ----------------------

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# append to the history file, don't overwrite it
shopt -s histappend

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# immediately append history
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"


# ----------------------
# Includes
# ----------------------

#for i in "$HOME"/.bash_{aliases,functions,integrations,path,prompt}; do
#	# Handle absence of any scripts (or the folder) gracefully
#	[ ! -f "$i" ] || . "$i"
#done
#unset i

[ -f ~/.bash_aliases ]   && . ~/.bash_aliases
[ -f ~/.bash_functions ] && . ~/.bash_functions


# ----------------------
# Integrations
# ----------------------

# fzf
# https://github.com/junegunn/fzf
# ----------------------

if [ -x ~/scoop/shims/fzf ] || [ -x /usr/bin/fzf ]; then
	# Set up fzf key bindings and fuzzy completion
	eval "$(fzf --bash)"
fi


# zoxide - Smart `cd`
# https://github.com/ajeetdsouza/zoxide
# ----------------------

if [ -x ~/scoop/shims/zoxide ] || [ -x /usr/bin/zoxide ]; then
	eval "$(zoxide init bash)"
fi


# ----------------------
# Path
# ----------------------

if [[ $OS == "windows" ]]; then
	# Use up-to-date and more feature-complete curl.
	PATH="~/scoop/apps/curl/current/bin:$PATH"
fi

# We use environment variables (with export) when we want to export
# the variables and make them available to the subsequent commands or
# processes. Normally we use this to share the environment with a child
# process: Configure the environment of the child process or shell.
# In short, better safe than sorry.
export PATH


# ----------------------
# Prompt
# ----------------------

# Since I want to customize the prompt and I DON'T want to double-run expensive git-prompt stuffs,
# .config/git/git-prompt.sh exists and is intentionally left empty.
# Git/Bash for Windows looks for that file and if it exists, skips setting up git-prompt.

# Taken from Windows' Git/etc/profile.d/git-prompt.sh

PS1='\n'                                       # new line
#PS1="$PS1"'${debian_chroot:+($debian_chroot)}' # idk what this does
PS1="$PS1"'\[\033[32m\]'                       # change to green
PS1="$PS1"'\u@\h '                             # user@host<space>
#PS1="$PS1"'\[\033[35m\]'                       # change to purple
#PS1="$PS1"'$MSYSTEM '                          # show MSYSTEM
PS1="$PS1"'\[\033[33m\]'                       # change to brownish yellow
PS1="$PS1"'\w'                                 # current working directory

if [[ $OS == "windows" ]] && test -z "$WINELOADERNOEXEC"; then
	GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
	COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
	COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
	COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"

	if test -f "$COMPLETION_PATH/git-prompt.sh"; then
		. "$COMPLETION_PATH/git-completion.bash"
		. "$COMPLETION_PATH/git-prompt.sh"
	fi
fi

PS1="$PS1"'\[\033[36m\]'                       # change color to cyan
PS1="$PS1"'`__git_ps1`'                        # bash function
PS1="$PS1"'\[\033[0m\]'                        # change color
PS1="$PS1"'\n'                                 # new line
PS1="$PS1"'$ '                                 # prompt: always $


# Taken from Ubuntu's .bashrc.

# If this is an xterm set the title to user@host:dir
case "$TERM" in
	xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1" ;;
esac
