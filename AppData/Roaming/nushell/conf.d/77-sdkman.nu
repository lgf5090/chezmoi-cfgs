if (($env.SDKMAN_DIR? | default "") | is-empty) {
    $env.SDKMAN_DIR = ($nu.home-dir | path join ".sdkman")
}
