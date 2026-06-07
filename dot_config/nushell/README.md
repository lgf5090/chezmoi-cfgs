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

- `config.nu`: small entry file.
- `conf.d/*.nu`: startup config, tools, prompt.
- `functions/*.nu`: shell functions.
- `completions/*.nu`: custom completion functions.

## Nushell Source Rule

Nushell parses `source` at parse time. Unlike zsh/bash/fish, it cannot reliably
loop over a directory and source files dynamically.

So this project keeps the same directory shape, but `config.nu` contains a
static source list. When you add a new file, add one source line to `config.nu`.

## Use

```nu
source /tmp/nushell/config.nu
```

## Use As Native Nushell Config

```sh
ln -s /tmp/nushell ~/.config/nushell
```

Interactive `nu` will load `~/.config/nushell/config.nu`.

For non-interactive checks, use:

```sh
nu --config ~/.config/nushell/config.nu --commands '...'
```

## Add A Tool

Create a file:

```text
conf.d/60-your-tool.nu
```

Then add a matching `source (...)` line in `config.nu`.

## Add A Function

Create a file:

```text
functions/your-function.nu
```

Then add a matching `source (...)` line in `config.nu`.
