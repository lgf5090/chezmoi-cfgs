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
