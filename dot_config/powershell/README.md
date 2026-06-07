# powershell

PowerShell configuration with the same project layout as `/tmp/zsh`.

## Layout

```text
powershell/
  config.ps1
  conf.d/
  functions/
  completions/
```

- `config.ps1`: small entry file.
- `conf.d/*.ps1`: startup config, tools, modules. Loaded by filename order.
- `functions/*.ps1`: shell functions. Loaded by filename order.
- `completions/*.ps1`: argument completers. Loaded by filename order.

## Use

```powershell
. /tmp/powershell/config.ps1
```

## Use As Native PowerShell Config

Linux/macOS:

```sh
ln -s /tmp/powershell ~/.config/powershell
```

Windows:

```powershell
New-Item -ItemType SymbolicLink -Path (Split-Path $PROFILE) -Target C:\path\to\powershell
```

The profile wrappers `Microsoft.PowerShell_profile.ps1` and `profile.ps1`
source `config.ps1`.

## Add A Tool

Add a file only:

```text
conf.d/60-your-tool.ps1
```

## Local Env And Alias Files

`conf.d/35-local-env.ps1` loads `~/.envs` if it exists:

```text
FOO=bar
EDITOR=nvim
PATH={HOME}/.local/custom/bin:{PATH}
```

- Lines must be `KEY=VALUE`.
- Full-line comments and invalid variable names are ignored.
- Matching outer single or double quotes are stripped.
- `{HOME}` and `{PATH}` are expanded without using `Invoke-Expression`.
- `PATH` is split on `:` and `;` on Unix-like systems, and on `;` on Windows.

`conf.d/45-local-aliases.ps1` loads `~/.aliases` if it exists:

```text
gs="git status"
ll="Get-ChildItem -Force"
```

Aliases load after the default aliases, so local aliases can override them.
They are implemented as global functions that append `@args` to the command
body. Repeated loads are skipped while the file mtime is unchanged.

Alias bodies are PowerShell command text. POSIX-only forms such as inline
`NAME=value command` assignments may need a PowerShell-specific alias body.

## Add A Function

Add a file only:

```text
functions/your-function.ps1
```

## Add Completion

Add a file only:

```text
completions/your-command.ps1
```
