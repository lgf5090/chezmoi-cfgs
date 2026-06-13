$env.SHELLS_OS = (
    match $nu.os-info.name {
        "linux" => (
            if ("/proc/version" | path exists) and (
                open --raw /proc/version | str downcase | (
                    ($in | str contains "microsoft") or ($in | str contains "wsl")
                )
            ) {
                "wsl"
            } else {
                "linux"
            }
        )
        "macos" => "macos"
        "freebsd" => "freebsd"
        "windows" => "windows"
        _ => "unknown"
    }
)
