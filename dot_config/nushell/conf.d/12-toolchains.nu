# Language and toolchain environment variables used by 15-path.nu.
# Existing values are respected so ~/.envs or parent shells can override.

def --env _nu_set_env_if_missing [name: string, value: string] {
    if ($value | is-empty) { return }
    if (($env | get -o $name | default "") | is-not-empty) { return }

    load-env { ($name): $value }
}

def --env _nu_set_env_dir_if_missing [name: string, ...dirs: string] {
    if (($env | get -o $name | default "") | is-not-empty) { return }

    for dir in $dirs {
        if ($dir | is-empty) { continue }
        if not (($dir | path exists) and (($dir | path type) == "dir")) { continue }

        load-env { ($name): $dir }
        return
    }
}

def --env _nu_env_path_prepend [name: string, dir: string] {
    if not (($dir | path exists) and (($dir | path type) == "dir")) { return }

    let current = ($env | get -o $name | default "")
    let parts = if ($current | is-empty) {
        []
    } else {
        $current | split row (char path_sep)
    }

    let next = (
        $parts
        | where { |p| $p != $dir }
        | prepend $dir
        | str join (char path_sep)
    )
    load-env { ($name): $next }
}

_nu_set_env_if_missing NPM_CONFIG_PREFIX ($nu.home-dir | path join ".npm-global")
_nu_set_env_if_missing PNPM_HOME ($nu.home-dir | path join ".pnpm-global")

_nu_set_env_dir_if_missing FNM_DIR ...[
    ($env.XDG_DATA_HOME | path join "fnm")
    ($nu.home-dir | path join ".fnm")
]

_nu_set_env_dir_if_missing VOLTA_HOME ($nu.home-dir | path join ".volta")
_nu_set_env_dir_if_missing BUN_INSTALL ($nu.home-dir | path join ".bun")
_nu_set_env_dir_if_missing DENO_INSTALL ($nu.home-dir | path join ".deno")

_nu_set_env_if_missing GOPATH ($nu.home-dir | path join "go")
_nu_set_env_dir_if_missing GOROOT ...[
    "/home/linuxbrew/.linuxbrew/opt/go/libexec"
    "/opt/homebrew/opt/go/libexec"
    "/usr/local/go"
    ($nu.home-dir | path join ".local" "go")
]

_nu_set_env_dir_if_missing ANACONDA_HOME ...[
    ($nu.home-dir | path join "anaconda3")
    ($nu.home-dir | path join "miniconda3")
    "/opt/anaconda3"
    "/opt/miniconda3"
]

_nu_set_env_dir_if_missing POETRY_HOME ($nu.home-dir | path join ".poetry")
_nu_set_env_dir_if_missing PYENV_ROOT ($nu.home-dir | path join ".pyenv")

let asdf_candidates = (
    [
        ($nu.home-dir | path join ".asdf")
        "/home/linuxbrew/.linuxbrew/opt/asdf/libexec"
        "/opt/homebrew/opt/asdf/libexec"
        "/usr/local/opt/asdf/libexec"
    ]
    | prepend (if (($env.HOMEBREW_PREFIX? | default "") | is-empty) { "" } else { $env.HOMEBREW_PREFIX | path join "opt" "asdf" "libexec" })
)
_nu_set_env_dir_if_missing ASDF_DIR ...$asdf_candidates

if (($env.ASDF_DATA_DIR? | default "") | is-empty) and (($env.ASDF_DIR? | default "") | is-not-empty) {
    if $env.ASDF_DIR == ($nu.home-dir | path join ".asdf") {
        $env.ASDF_DATA_DIR = $env.ASDF_DIR
    } else {
        $env.ASDF_DATA_DIR = ($env.XDG_DATA_HOME | path join "asdf")
    }
}

_nu_set_env_dir_if_missing RBENV_ROOT ($nu.home-dir | path join ".rbenv")
_nu_set_env_dir_if_missing NODENV_ROOT ($nu.home-dir | path join ".nodenv")
_nu_set_env_dir_if_missing GOENV_ROOT ($nu.home-dir | path join ".goenv")
_nu_set_env_dir_if_missing JENV_ROOT ($nu.home-dir | path join ".jenv")
_nu_set_env_dir_if_missing SDKMAN_DIR ($nu.home-dir | path join ".sdkman")

if (($env.JAVA_HOME? | default "") | is-empty) {
    if ("/usr/libexec/java_home" | path exists) {
        let java_home = (try { ^/usr/libexec/java_home | str trim } catch { "" })
        if ($java_home | is-not-empty) { $env.JAVA_HOME = $java_home }
    } else {
        _nu_set_env_dir_if_missing JAVA_HOME ...[
            "/usr/lib/jvm/default-java"
            "/usr/lib/jvm/default"
            "/usr/lib/jvm/java-21-openjdk-amd64"
            "/usr/lib/jvm/java-17-openjdk-amd64"
            "/usr/lib/jvm/java-11-openjdk-amd64"
        ]
    }
}

if $env.SHELLS_OS in ["linux" "wsl"] {
    for dir in ["/usr/lib/x86_64-linux-gnu" "/usr/lib/aarch64-linux-gnu"] {
        if not (($dir | path exists) and (($dir | path type) == "dir")) { continue }

        _nu_env_path_prepend LIBRARY_PATH $dir
        _nu_env_path_prepend LD_LIBRARY_PATH $dir

        let rustflags = ($env.RUSTFLAGS? | default "")
        if not ($" ($rustflags) " | str contains $"-L ($dir)") {
            if ($rustflags | is-empty) {
                $env.RUSTFLAGS = $"-L ($dir)"
            } else {
                $env.RUSTFLAGS = $"-L ($dir) ($rustflags)"
            }
        }
        break
    }
}

_nu_set_env_if_missing DOCKER_BUILDKIT "1"
_nu_set_env_if_missing COMPOSE_DOCKER_CLI_BUILD "1"
