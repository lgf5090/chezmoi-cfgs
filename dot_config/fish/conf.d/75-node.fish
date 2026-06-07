set -q NPM_CONFIG_PREFIX; or set -gx NPM_CONFIG_PREFIX "$HOME/.npm-global"
set -q PNPM_HOME; or set -gx PNPM_HOME "$HOME/.pnpm-global"

test -d "$NPM_CONFIG_PREFIX/bin"; and _fpath_prepend "$NPM_CONFIG_PREFIX/bin"
test -d "$PNPM_HOME"; and _fpath_prepend "$PNPM_HOME"
test -d "$HOME/.bun/bin"; and _fpath_prepend "$HOME/.bun/bin"
test -d "$HOME/.deno/bin"; and _fpath_prepend "$HOME/.deno/bin"
