# zsh

Fish-style zsh configuration.

## Layout

```text
zsh/
  config.zsh
  conf.d/
  functions/
  completions/
```

- `config.zsh`: small entry file.
- `conf.d/*.zsh`: startup config, tools, plugins. Loaded by filename order.
- `functions/*.zsh`: shell functions. Loaded by filename order.
- `completions/_cmd`: zsh completion definitions. Added to `fpath`.

## Use

```zsh
source /tmp/zsh/config.zsh
```

## Use As Native zsh Config

```zsh
ln -s /tmp/zsh ~/.config/zsh
```

zsh does not read `~/.config/zsh` by default. Add this once to `~/.zshenv`:

```zsh
export ZDOTDIR="$HOME/.config/zsh"
```

Then start a new zsh. The wrapper `.zshrc` in this directory sources
`config.zsh`.

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.zsh
```

No change is needed in `config.zsh`.

## Add A Plugin

Add a file only:

```zsh
_zplugin owner repo
```

Example:

```zsh
_zplugin zsh-users zsh-completions
```
