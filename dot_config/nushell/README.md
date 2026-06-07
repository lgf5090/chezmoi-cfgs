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

## Add A Function

Create a file:

```text
functions/your-function.nu
```
