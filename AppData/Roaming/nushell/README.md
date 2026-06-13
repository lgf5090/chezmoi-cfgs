# nushell

Nushell configuration with the same project layout as `/tmp/zsh`.

## Layout

```text
nushell/
  config.nu
  conf.d/
  functions/
  completions/
```

- `config.nu`: generates the vendor autoload loader at startup.
- `conf.d/*.nu`: startup config, tools, prompt.
- `functions/*.nu`: shell functions.
- `completions/*.nu`: custom completion functions.

## Autoload

Nushell parses `source` at parse time. `config.nu` uses Nushell built-ins to
generate a static loader in Nushell's vendor autoload directory:

```text
$nu.data-dir/vendor/autoload/auto-generate-autoload.nu
```

The generated loader sources files in this order:

```text
completions/*.nu
functions/*.nu
conf.d/*.nu
```

When you add, rename, or remove a file, run:

```sh
exec nu
```

The autoload file is regenerated automatically. Do not edit it manually.

## Use

```sh
chezmoi apply
nu
```

## Use As Native Nushell Config

```sh
ln -s /tmp/nushell ~/.config/nushell
```

Interactive `nu` will load `config.nu` from its active config directory and the
generated vendor autoload file.

For non-interactive checks, use:

```sh
nu --commands '...'
```

## Add A Tool

Create a file:

```text
conf.d/60-your-tool.nu
```

Use adjacent numbers inside the same category. Current Nushell tool ranges:

- `60-69`: interactive CLI integrations such as `fzf`, `zoxide`, `lf`.
- `70-79`: runtime, package, and environment managers such as `mise`, `asdf`,
  `pyenv`, `fnm`, `nvm`, `conda`, `SDKMAN`, `direnv`, and `poetry`.

## Local Env And Alias Files

`conf.d/11-local-env.nu` loads `~/.envs` if it exists:

```text
FOO=bar
EDITOR=nvim
PATH={HOME}/.local/custom/bin:{PATH}
```

- Lines must be `KEY=VALUE`; `export KEY=VALUE` is also accepted.
- Full-line comments and invalid variable names are ignored.
- Matching outer single or double quotes are stripped.
- `{HOME}` and `{PATH}` are expanded without using dynamic evaluation.
- `PATH` is prepended in the written order, with missing directories skipped.

`conf.d/45-local-aliases.nu` checks `~/.aliases` and regenerates:

```text
$nu.data-dir/vendor/autoload/zz-local-aliases.nu
```

Example `~/.aliases`:

```text
gs="git status"
ll="ls -la"
```

Nushell aliases are parse-time definitions, so they cannot be loaded by a
runtime loop in an already-running session. When `~/.aliases` is newer than the
cache, `shells-regen-aliases` rewrites the vendor autoload file. Run `exec nu`
after editing `~/.aliases` to start a fresh parse with the new aliases.

The cache filename starts with `zz-` so it is loaded after
`auto-generate-autoload.nu`; local aliases can override defaults from
`conf.d/40-aliases.nu`. `config.nu` creates a placeholder cache file when it is
missing, so the first interactive `nu` startup can regenerate and then load the
cache in the same startup.

Alias bodies are Nushell command text. POSIX-only forms such as inline
`NAME=value command` assignments may need a Nushell-specific alias body.

## Add A Function

Create a file:

```text
functions/your-function.nu
```
