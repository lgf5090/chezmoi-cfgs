alias ll = ls -la
alias la = ls -a
alias l = ls
alias md = mkdir
alias cls = clear

def lt [path?: string] {
    let items = if ($path | is-empty) { ls -la } else { ls -la $path }
    $items | sort-by modified --reverse
}

alias grep = ^grep --color=auto
alias fgrep = ^fgrep --color=auto
alias egrep = ^egrep --color=auto

def now [] {
    date now | format date "%Y-%m-%dT%H:%M:%S%z"
}

def reload [] {
    exec nu
}

def dotfiles [...args] {
    let dotfiles_dir = $env.HOME | path join '.dotfiles'
    ^git --git-dir $dotfiles_dir --work-tree $env.HOME ...$args
}