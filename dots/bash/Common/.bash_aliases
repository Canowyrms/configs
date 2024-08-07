# ----------------------
# Bash Aliases
# ----------------------

# Quick cd
# ----------------------

alias ..='cd ..'         # Up one
alias ...='cd ../..'     # Up two
alias ....='cd ../../..' # Up three


# Git Aliases
# ----------------------

alias gc='git clone'
alias gs='git status'
alias gf='git fetch'
alias gp='git pull'
alias gr='git remote'
alias grv='git remote -v'
alias gfp='gf && gp'
alias gcm='git commit -m'


# Grep
# ----------------------

# Colored grep
alias grep='grep --color=auto'


# Laravel Sail
# ----------------------

alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'

alias sup='sail up'
alias supd='sail up -d'
alias sdown='sail stop'
alias sstop='sdown'

alias sartisan='sail artisan'
alias scomposer='sail composer'
alias snpm='sail npm'
alias sphp='sail php'

alias saila='sartisan'
alias sailc='scomposer'
alias sailn='snpm'
alias sailp='sphp'


# Python stuffs
# ----------------------

alias pip='pip3'


# Windows Binaries
# ----------------------

alias glow='glow.exe'


# yt-dlp
# ----------------------

alias yt-dlp='python ~/code/repos/python/yt-dlp/yt_dlp/__main__.py'
alias yt='yt-dlp'
