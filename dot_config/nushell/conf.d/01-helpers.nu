def _nu_path_list [] {
    if (($env.PATH | describe) | str starts-with "list") {
        $env.PATH
    } else {
        $env.PATH | split row (char path_sep)
    }
}

def --env _nu_path_prepend [...dirs: string] {
    mut paths = (_nu_path_list)

    for dir in $dirs {
        if ($dir | is-empty) { continue }
        if not (($dir | path exists) and (($dir | path type) == "dir")) { continue }

        $paths = ($paths | where { |p| $p != $dir } | prepend $dir)
    }

    $env.PATH = $paths
}

def --env _nu_path_append [...dirs: string] {
    mut paths = (_nu_path_list)

    for dir in $dirs {
        if ($dir | is-empty) { continue }
        if not (($dir | path exists) and (($dir | path type) == "dir")) { continue }

        $paths = ($paths | where { |p| $p != $dir } | append $dir)
    }

    $env.PATH = $paths
}

def _nu_first_dir [...dirs: string] {
    for dir in $dirs {
        if ($dir | is-not-empty) and ($dir | path exists) and (($dir | path type) == "dir") {
            return $dir
        }
    }

    null
}

def _nu_ver_ge [left: string, right: string] {
    let l = ($left | split row ".")
    let r = ($right | split row ".")

    for i in 0..2 {
        mut ln = "0"
        mut rn = "0"
        if ($l | length) > $i { $ln = ($l | get $i | str replace -r '[^0-9].*$' '') }
        if ($r | length) > $i { $rn = ($r | get $i | str replace -r '[^0-9].*$' '') }
        if ($ln | is-empty) { $ln = "0" }
        if ($rn | is-empty) { $rn = "0" }

        if ($ln | into int) > ($rn | into int) { return true }
        if ($ln | into int) < ($rn | into int) { return false }
    }

    true
}

if ($env.NUSHELL_PLUGIN_DIR? | is-empty) {
    $env.NUSHELL_PLUGIN_DIR = ($env.XDG_DATA_HOME | path join "nushell" "plugins")
}
if ($env.NUSHELL_PLUGIN_AUTO_INSTALL? | is-empty) {
    $env.NUSHELL_PLUGIN_AUTO_INSTALL = "1"
}

def nuplugin-update [] {
    if (which git | is-empty) {
        print -e "nushell: git not found"
        return
    }
    if not ($env.NUSHELL_PLUGIN_DIR | path exists) { return }

    for dir in (ls $env.NUSHELL_PLUGIN_DIR | where type == dir | get name) {
        if ($dir | path join ".git" | path exists) {
            print $"Updating ($dir | path basename)..."
            ^git -C $dir pull --ff-only
        }
    }
}

# Nushell source paths are parse-time constants, so this helper only installs or
# updates git-backed script directories. Add static source lines in config.nu to
# load files from installed plugins.
def _nuplugin [owner: string, repo: string] {
    let dir = ($env.NUSHELL_PLUGIN_DIR | path join $repo)
    if ($dir | path exists) { return }

    if $env.NUSHELL_PLUGIN_AUTO_INSTALL != "1" {
        print -e $"nushell: plugin missing, skip ($repo)"
        return
    }
    if (which git | is-empty) {
        print -e $"nushell: git not found, skip ($repo)"
        return
    }

    mkdir $env.NUSHELL_PLUGIN_DIR
    ^git clone --depth=1 $"https://github.com/($owner)/($repo)" $dir
}
