# fish

Fish configuration with the same project layout as `/tmp/zsh`.

## Layout

```text
fish/
  config.fish
  conf.d/
  functions/
  completions/
```

- `config.fish`: small entry file.
- `conf.d/*.fish`: startup config, tools, plugins. Loaded by fish by filename order.
- `functions/*.fish`: shell functions. Autoloaded by fish.
- `completions/*.fish`: fish completions. Discovered by fish.

## Use As Native Fish Config

```sh
ln -s /tmp/fish ~/.config/fish
```

If `~/.config/fish` already exists, move or merge it first.

```fish
exec fish
```

Fish will load `conf.d/`, `functions/`, and `completions/` through its native
startup conventions.

## Use From Another Config

```fish
source /tmp/fish/config.fish
```

In this mode, `config.fish` adds this project's `functions/` and `completions/`
paths, then sources this project's `conf.d/*.fish`.

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.fish
```

## Add A Function

Add a file only:

```text
functions/your-function.fish
```

## Add Completion

Add a file only:

```text
completions/your-command.fish
```
