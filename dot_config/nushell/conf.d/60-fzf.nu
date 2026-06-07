if (which fd | is-not-empty) {
    $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --strip-cwd-prefix"
} else {
    $env.FZF_DEFAULT_COMMAND = ""
}

$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_DEFAULT_OPTS = "--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left"

if (which bat | is-not-empty) {
    $env._FZF_PREVIEW_CMD = "bat --color=always --style=plain,numbers --line-range=:500 {}"
} else if (which batcat | is-not-empty) {
    $env._FZF_PREVIEW_CMD = "batcat --color=always --style=plain,numbers --line-range=:500 {}"
} else {
    $env._FZF_PREVIEW_CMD = ""
}

def fzf-file [] {
    if (which fzf | is-empty) { return "" }

    let items = if (which fd | is-not-empty) {
        ^fd --type f --strip-cwd-prefix | lines
    } else {
        ls -a **/* | where type == file | get name
    }

    if ($env._FZF_PREVIEW_CMD? | default "" | is-empty) {
        $items | str join "\n" | ^fzf
    } else {
        $items | str join "\n" | ^fzf --preview $env._FZF_PREVIEW_CMD
    }
}
