switch $SHELLS_OS
    case linux wsl cygwin windows
        alias ls 'ls --color=auto'
    case macos freebsd
        alias ls 'ls -G'
end

alias ll 'ls -alFh'
alias la 'ls -A'
alias l 'ls -CF'
alias lt 'ls -alFht'

alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'

alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias md 'mkdir -p'
alias now 'date +%Y-%m-%dT%H:%M:%S%z'
alias cls clear
alias reload 'source "$FISH_CONFIG_DIR/config.fish"'
