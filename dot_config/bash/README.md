# bash

Fish-style bash configuration.

## Layout

```text
bash/
  config.bash
  conf.d/
  functions/
  completions/
```

- `config.bash`: small entry file.
- `conf.d/*.bash`: startup config, tools, plugins. Loaded by filename order.
- `functions/*.bash`: shell functions. Loaded by filename order.
- `completions/*.bash`: bash completion registrations. Loaded by filename order.

## Use

```bash
source /tmp/bash/config.bash
```

## Use As Native bash Config

```bash
ln -s /tmp/bash ~/.config/bash
```

bash does not read `~/.config/bash` by default. Add this once to `~/.bashrc`:

```bash
source "$HOME/.config/bash/.bashrc"
```

For login shells, also add this to `~/.bash_profile` if needed:

```bash
source "$HOME/.config/bash/.bash_profile"
```

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.bash
```

No change is needed in `config.bash`.

## Add A Function

Add a file only:

```text
functions/your-function.bash
```

## Add Completion

Add a file only:

```text
completions/your-command.bash
```
