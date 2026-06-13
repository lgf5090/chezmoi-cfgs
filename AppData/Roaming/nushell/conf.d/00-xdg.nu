if ($env.XDG_CONFIG_HOME? | is-empty) {
    $env.XDG_CONFIG_HOME = (
        if $nu.os-info.name == "windows" {
            $env.APPDATA? | default ($nu.home-dir | path join "AppData" "Roaming")
        } else {
            $nu.home-dir | path join ".config"
        }
    )
}

if ($env.XDG_DATA_HOME? | is-empty) {
    $env.XDG_DATA_HOME = (
        if $nu.os-info.name == "windows" {
            $env.LOCALAPPDATA? | default ($nu.home-dir | path join "AppData" "Local")
        } else {
            $nu.home-dir | path join ".local" "share"
        }
    )
}

if ($env.XDG_CACHE_HOME? | is-empty) {
    $env.XDG_CACHE_HOME = (
        if $nu.os-info.name == "windows" {
            ($env.LOCALAPPDATA? | default ($nu.home-dir | path join "AppData" "Local")) | path join "cache"
        } else {
            $nu.home-dir | path join ".cache"
        }
    )
}

if ($env.XDG_STATE_HOME? | is-empty) {
    $env.XDG_STATE_HOME = (
        if $nu.os-info.name == "windows" {
            ($env.LOCALAPPDATA? | default ($nu.home-dir | path join "AppData" "Local")) | path join "state"
        } else {
            $nu.home-dir | path join ".local" "state"
        }
    )
}

let nushell_state_dir = ($env.XDG_STATE_HOME | path join "nushell")
let nushell_cache_dir = ($env.XDG_CACHE_HOME | path join "nushell")

if (($nushell_state_dir | path type) != "dir") { mkdir $nushell_state_dir }
if (($nushell_cache_dir | path type) != "dir") { mkdir $nushell_cache_dir }
