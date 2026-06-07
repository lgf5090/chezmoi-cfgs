if ($env.NPM_CONFIG_PREFIX? | is-empty) { $env.NPM_CONFIG_PREFIX = ($nu.home-dir | path join ".npm-global") }
if ($env.PNPM_HOME? | is-empty) { $env.PNPM_HOME = ($nu.home-dir | path join ".pnpm-global") }

_nu_path_prepend ...[
    ($env.NPM_CONFIG_PREFIX | path join "bin")
    $env.PNPM_HOME
    ($nu.home-dir | path join ".bun" "bin")
    ($nu.home-dir | path join ".deno" "bin")
    ($nu.home-dir | path join ".volta" "bin")
    ($nu.home-dir | path join ".fnm")
]
