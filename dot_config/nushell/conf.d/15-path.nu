_nu_path_append ...[
    ($nu.home-dir | path join ".local" "bin")
    ($nu.home-dir | path join "bin")
    ($nu.home-dir | path join "Applications")
]

_nu_path_prepend ...[
    ($nu.home-dir | path join ".cargo" "bin")
    ($nu.home-dir | path join ".rd" "bin")
    ($nu.home-dir | path join ".opencode" "bin")
]

if $env.SHELLS_OS == "windows" {
    _nu_path_prepend ...[
        ($nu.home-dir | path join "scoop" "shims")
        ($env.LOCALAPPDATA? | default "" | path join "Microsoft" "WindowsApps")
        ($env.APPDATA? | default "" | path join "npm")
    ]
} else {
    _nu_path_prepend ...[
        "/home/linuxbrew/.linuxbrew/bin"
        "/home/linuxbrew/.linuxbrew/sbin"
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/usr/local/bin"
    ]
}
