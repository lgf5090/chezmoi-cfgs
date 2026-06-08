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

- `config.nu`: small placeholder loaded by Nushell.
- `conf.d/*.nu`: startup config, tools, prompt.
- `functions/*.nu`: shell functions.
- `completions/*.nu`: custom completion functions.

## Autoload

Nushell parses `source` at parse time. This project keeps `config.nu` small and
uses a chezmoi `run_onchange` template to generate a static loader at:

```nu
$nu.data-dir | path join "vendor" "autoload" "chezmoi-dotfiles.nu"
```

The generated loader sources files in this order:

```text
completions/*.nu
functions/*.nu
conf.d/*.nu
```

When you add, rename, or remove a file, run:

```sh
chezmoi apply
```

The autoload file is regenerated automatically. No manual edit to `config.nu`
is needed.

## Use

```sh
chezmoi apply
nu
```

## Use As Native Nushell Config

```sh
ln -s /tmp/nushell ~/.config/nushell
```

Interactive `nu` will load `~/.config/nushell/config.nu` and the generated
vendor autoload file.

For non-interactive checks, use:

```sh
nu --commands '...'
```

## Add A Tool

Create a file:

```text
conf.d/60-your-tool.nu
```

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

```nu
$nu.data-dir | path join "vendor" "autoload" "zz-local-aliases.nu"
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
`chezmoi-dotfiles.nu`; local aliases can override defaults from
`conf.d/40-aliases.nu`. The chezmoi autoload generator creates a placeholder
cache file when it is missing, so the first interactive `nu` startup after
`chezmoi apply` can regenerate and then load the cache in the same startup.

Alias bodies are Nushell command text. POSIX-only forms such as inline
`NAME=value command` assignments may need a Nushell-specific alias body.

## Add A Function

Create a file:

```text
functions/your-function.nu
```
