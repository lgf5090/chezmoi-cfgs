# Language and toolchain environment variables used by 15-path.nu.
# Existing values are respected so ~/.envs or parent shells can override.

def _nu_prepend_env_path_value [current: string, dir: string] {
    if not (_nu_is_dir $dir) { return $current }

    let parts = if ($current | is-empty) {
        []
    } else {
        $current | split row (char path_sep)
    }

    $parts | where { |p| $p != $dir } | prepend $dir | str join (char path_sep)
}

if (($env.NPM_CONFIG_PREFIX? | default "") | is-empty) {
    $env.NPM_CONFIG_PREFIX = ($nu.home-dir | path join ".npm-global")
}
if (($env.PNPM_HOME? | default "") | is-empty) {
    $env.PNPM_HOME = ($nu.home-dir | path join ".pnpm-global")
}

if (($env.MISE_DATA_DIR? | default "") | is-empty) {
    $env.MISE_DATA_DIR = ($env.XDG_DATA_HOME | path join "mise")
}

if (($env.FNM_DIR? | default "") | is-empty) {
    let dir = (_nu_first_dir
        ($env.XDG_DATA_HOME | path join "fnm")
        ($nu.home-dir | path join ".fnm")
    )
    if ($dir | is-not-empty) { $env.FNM_DIR = $dir }
}

if (($env.VOLTA_HOME? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".volta"))
    if ($dir | is-not-empty) { $env.VOLTA_HOME = $dir }
}
if (($env.BUN_INSTALL? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".bun"))
    if ($dir | is-not-empty) { $env.BUN_INSTALL = $dir }
}
if (($env.DENO_INSTALL? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".deno"))
    if ($dir | is-not-empty) { $env.DENO_INSTALL = $dir }
}

if (($env.GOPATH? | default "") | is-empty) {
    $env.GOPATH = ($nu.home-dir | path join "go")
}
if (($env.GOROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir
        "/home/linuxbrew/.linuxbrew/opt/go/libexec"
        "/opt/homebrew/opt/go/libexec"
        "/usr/local/go"
        ($nu.home-dir | path join ".local" "go")
    )
    if ($dir | is-not-empty) { $env.GOROOT = $dir }
}

if (($env.ANACONDA_HOME? | default "") | is-empty) {
    let dir = (_nu_first_dir
        ($nu.home-dir | path join "anaconda3")
        ($nu.home-dir | path join "miniconda3")
        "/opt/anaconda3"
        "/opt/miniconda3"
    )
    if ($dir | is-not-empty) { $env.ANACONDA_HOME = $dir }
}

if (($env.POETRY_HOME? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".poetry"))
    if ($dir | is-not-empty) { $env.POETRY_HOME = $dir }
}
if (($env.PYENV_ROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".pyenv"))
    if ($dir | is-not-empty) { $env.PYENV_ROOT = $dir }
}

if (($env.ASDF_DIR? | default "") | is-empty) {
    let dir = (_nu_first_dir
        (if (($env.HOMEBREW_PREFIX? | default "") | is-empty) { "" } else { $env.HOMEBREW_PREFIX | path join "opt" "asdf" "libexec" })
        ($nu.home-dir | path join ".asdf")
        "/home/linuxbrew/.linuxbrew/opt/asdf/libexec"
        "/opt/homebrew/opt/asdf/libexec"
        "/usr/local/opt/asdf/libexec"
    )
    if ($dir | is-not-empty) { $env.ASDF_DIR = $dir }
}

if (($env.ASDF_DATA_DIR? | default "") | is-empty) and (($env.ASDF_DIR? | default "") | is-not-empty) {
    if $env.ASDF_DIR == ($nu.home-dir | path join ".asdf") {
        $env.ASDF_DATA_DIR = $env.ASDF_DIR
    } else {
        $env.ASDF_DATA_DIR = ($env.XDG_DATA_HOME | path join "asdf")
    }
}

if (($env.RBENV_ROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".rbenv"))
    if ($dir | is-not-empty) { $env.RBENV_ROOT = $dir }
}
if (($env.NODENV_ROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".nodenv"))
    if ($dir | is-not-empty) { $env.NODENV_ROOT = $dir }
}
if (($env.GOENV_ROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".goenv"))
    if ($dir | is-not-empty) { $env.GOENV_ROOT = $dir }
}
if (($env.JENV_ROOT? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".jenv"))
    if ($dir | is-not-empty) { $env.JENV_ROOT = $dir }
}
if (($env.SDKMAN_DIR? | default "") | is-empty) {
    let dir = (_nu_first_dir ($nu.home-dir | path join ".sdkman"))
    if ($dir | is-not-empty) { $env.SDKMAN_DIR = $dir }
}

if (($env.JAVA_HOME? | default "") | is-empty) {
    if ($env.SHELLS_OS == "macos") and ("/usr/libexec/java_home" | path exists) {
        let java_home = (try { ^/usr/libexec/java_home | str trim } catch { "" })
        if ($java_home | is-not-empty) { $env.JAVA_HOME = $java_home }
    } else {
        let dir = (_nu_first_dir
            "/usr/lib/jvm/default-java"
            "/usr/lib/jvm/default"
            "/usr/lib/jvm/java-21-openjdk-amd64"
            "/usr/lib/jvm/java-17-openjdk-amd64"
            "/usr/lib/jvm/java-11-openjdk-amd64"
        )
        if ($dir | is-not-empty) { $env.JAVA_HOME = $dir }
    }
}

if $env.SHELLS_OS in ["linux" "wsl"] {
    for dir in ["/usr/lib/x86_64-linux-gnu" "/usr/lib/aarch64-linux-gnu"] {
        if not (_nu_is_dir $dir) { continue }

        $env.LIBRARY_PATH = (_nu_prepend_env_path_value ($env.LIBRARY_PATH? | default "") $dir)
        $env.LD_LIBRARY_PATH = (_nu_prepend_env_path_value ($env.LD_LIBRARY_PATH? | default "") $dir)

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

if (($env.DOCKER_BUILDKIT? | default "") | is-empty) {
    $env.DOCKER_BUILDKIT = "1"
}
if (($env.COMPOSE_DOCKER_CLI_BUILD? | default "") | is-empty) {
    $env.COMPOSE_DOCKER_CLI_BUILD = "1"
}
