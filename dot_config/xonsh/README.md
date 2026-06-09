# xonsh

Fish-style xonsh configuration.

## Layout

```text
xonsh/
  config.xsh
  conf.d/
  functions/
  completions/
```

- `config.xsh`: small entry file.
- `functions/*.xsh`: shell functions and callable aliases. Loaded by filename order.
- `conf.d/*.xsh`: startup config, tools, plugins. Loaded by filename order.
- `completions/*.xsh`: xonsh completion registrations. Loaded by filename order.

## Use

```xsh
source /tmp/xonsh/config.xsh
```

## Use As Native xonsh Config

```bash
ln -s /tmp/xonsh ~/.config/xonsh
```

xonsh reads `~/.xonshrc` by default. This chezmoi config keeps `~/.xonshrc`
small and sources:

```text
~/.config/xonsh/config.xsh
```

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.xsh
```

Use adjacent numbers inside the same category. Current xonsh tool ranges:

- `60-69`: interactive CLI integrations such as `fzf`, `zoxide`, `lf`.
- `70-79`: runtime, package, and environment managers such as `mise`, `asdf`,
  `pyenv`, `fnm`, `nvm`, `conda`, `SDKMAN`, `direnv`, and `poetry`.

No change is needed in `config.xsh`.

## Local Env And Alias Files

`conf.d/11-local-env.xsh` loads `~/.envs` if it exists:

```text
FOO=bar
EDITOR=nvim
PATH={HOME}/.local/custom/bin:{PATH}
```

- Lines must be `KEY=VALUE`.
- Full-line comments and invalid variable names are ignored.
- Matching outer single or double quotes are stripped.
- `{HOME}` and `{PATH}` are expanded without using `eval`.
- `PATH` is split on `:` and prepended in the written order.

`conf.d/45-local-aliases.xsh` loads `~/.aliases` if it exists:

```text
gs="git status"
ll="ls -alFh"
```

Aliases load after the default aliases, so local aliases can override them.

## Add A Function

Add a file only:

```text
functions/your-function.xsh
```

## Add Completion

Add a file only:

```text
completions/your-command.xsh
```
