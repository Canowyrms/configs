# ----------------------
# Bash Functions
# ----------------------


# Start Caddy fileserver in current directory.
# ----------------------

function caddy-fileserver () {
	caddy file-server --listen :80 --browse
}


# Git - List remote URLs for each repo in cwd.
# ----------------------

function git-list-remotes () {
	# Loop through each directory in the current folder
	for dir in */; do
		if [ -d "$dir/.git" ]; then
			echo "Dir: $dir"
			git -C "$dir" remote -v
			echo
		fi
	done
}


# Print $PATH with one path item per line.
# ----------------------

function nicepath () {
	echo $PATH | sed 's/:/\n/g'
}


# Start a PHP server in cwd, optionally specifying the port.
# ----------------------

function phpserver () {
	local port="${1:-3000}";
	php -S "localhost:${port}";
}


# Print working directory in Windows format.
# ----------------------

function pwdw () {
	pwd | sed -r -e 's/\///' -e 's/[a-zA-Z]/&:/' -e 's/\//\\/g'
}


# Start Mailpit with database.
# TODO - change DB location?
# ----------------------

function start-mailpit () {
	mailpit.exe -d "C:\Users\BK\mailpit.db" -v
}
