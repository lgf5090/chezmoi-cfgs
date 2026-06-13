# WindowsPowerShell 5.1 配置

这个目录是 Windows PowerShell 5.1 专用配置。它和
`dot_config/powershell` 分开维护，因为 `dot_config/powershell` 面向
PowerShell 7+ 和跨平台环境，包含不少 PowerShell 7 参数、Unix 路径和外部工具
hook。

## 文件结构

```text
Documents/WindowsPowerShell/
  Microsoft.PowerShell_profile.ps1
  profile.ps1
  config.ps1
  README.md
```

| 文件 | 作用 |
| --- | --- |
| `Microsoft.PowerShell_profile.ps1` | 当前用户、当前 Host 的 profile 入口 |
| `profile.ps1` | 当前用户、所有 Host 的 profile 入口 |
| `config.ps1` | Windows PowerShell 5.1 兼容配置 |
| `README.md` | 本说明文档 |

两个 profile 入口都会先检查 `config.ps1` 是否存在，存在才加载，避免文件未同步时启动报错。

## 设计目标

- 兼容 Windows PowerShell 5.1。
- 只使用 PowerShell 内置命令和 .NET Framework API。
- 不在启动时调用外部可执行文件。
- 不加载 PowerShell 7 专用参数或变量。
- 可选文件、状态目录、PSReadLine 参数不可用时不影响启动。
- 保留常用的环境变量、PATH 清理、PSReadLine、简单函数和本地配置文件能力。

## 启动行为

`config.ps1` 是独立配置，不会扫描或加载：

- `dot_config/powershell/conf.d`
- `dot_config/powershell/functions`
- `dot_config/powershell/completions`

启动时会设置：

| 项目 | 行为 |
| --- | --- |
| `$global:PowerShellConfigDir` | 指向 `Documents\WindowsPowerShell` |
| `$global:ShellsOS` | 固定为 `windows` |
| `$env:SHELLS_OS` | 固定为 `windows` |
| `XDG_CONFIG_HOME` | 默认 `%USERPROFILE%\.config` |
| `XDG_DATA_HOME` | 默认 `%USERPROFILE%\.local\share` |
| `XDG_STATE_HOME` | 默认 `%USERPROFILE%\.local\state` |
| `XDG_CACHE_HOME` | 默认 `%USERPROFILE%\.cache` |
| `EDITOR` | 默认 `notepad.exe` |
| `VISUAL` | 默认跟随 `EDITOR` |
| `CLICOLOR` | 默认 `1` |

状态目录和缓存目录会尽量创建；如果权限不足，启动会继续，不会中断。

## `.envs` 支持

默认读取：

```text
%USERPROFILE%\.envs
```

可以用环境变量改路径：

```powershell
$env:POWERSHELL_LOCAL_ENVS_FILE = 'C:\path\to\envs'
```

示例：

```text
FOO=bar
EDITOR=notepad.exe
PATH={HOME}\bin;{PATH}
```

规则：

- 空行和整行注释会被忽略。
- 支持可选的 `export ` 前缀。
- 变量名必须匹配 `^[A-Za-z_][A-Za-z0-9_]*$`。
- 成对的外层单引号或双引号会被去掉。
- `{HOME}` 会替换为用户主目录。
- `{PATH}` 会替换为当前进程 `PATH`。
- `PATH` 只按 Windows 分隔符 `;` 拆分。
- 只有已经存在的目录会加入 `PATH`。

## `.aliases` 支持

支持 `.aliases`。

默认读取：

```text
%USERPROFILE%\.aliases
```

可以用环境变量改路径：

```powershell
$env:POWERSHELL_LOCAL_ALIASES_FILE = 'C:\path\to\aliases'
```

示例：

```text
gs="git status"
ll="Get-ChildItem -Force"
gco="git checkout"
```

规则：

- 每行格式必须是 `NAME=BODY`。
- 空行和整行注释会被忽略。
- 名称必须匹配 `^[A-Za-z_][A-Za-z0-9_-]*$`。
- 成对的外层单引号或双引号会被去掉。
- 每个条目会生成一个全局函数：

```powershell
function global:NAME { BODY @args }
```

因此调用别名时传入的参数会自动追加到 `BODY` 后面。

注意事项：

- `BODY` 必须是合法的 PowerShell 代码。
- Bash/POSIX 写法不能直接通用，例如 `FOO=bar command`、`cmd && other`、
  Bash 参数展开等。
- 默认静默跳过无法编译的 alias body。
- 启动前设置 `POWERSHELL_ALIAS_WARNINGS=1` 可以显示无效 alias 的警告。
- `reload` 可以新增或更新 alias；如果从 `.aliases` 删除了某个 alias，当前会话里旧函数可能仍保留，重新开 shell 最干净。

## 开发环境变量

5.1 版本已经迁移 `dot_config/powershell/conf.d/12-toolchains.ps1` 中可静态设置的开发环境变量。这里的“静态”指只检查目录、设置环境变量、调整 `PATH`，不执行外部命令，也不加载外部工具生成的 hook。

会设置或探测：

| 环境变量 | 行为 |
| --- | --- |
| `NPM_CONFIG_PREFIX` | 默认 `%USERPROFILE%\.npm-global` |
| `PNPM_HOME` | 默认 `%USERPROFILE%\.pnpm-global` |
| `MISE_DATA_DIR` | 默认 `%XDG_DATA_HOME%\mise` |
| `FNM_DIR` | 探测 `%XDG_DATA_HOME%\fnm`、`%USERPROFILE%\.fnm` |
| `VOLTA_HOME` | 探测 `%USERPROFILE%\.volta` |
| `BUN_INSTALL` | 探测 `%USERPROFILE%\.bun` |
| `DENO_INSTALL` | 探测 `%USERPROFILE%\.deno` |
| `GOPATH` | 默认 `%USERPROFILE%\go` |
| `GOROOT` | 探测用户、本机和 `C:\Go` 常见安装路径 |
| `ANACONDA_HOME` | 探测用户目录、`LOCALAPPDATA`、`PROGRAMDATA` 下的 conda 目录 |
| `POETRY_HOME` | 探测 `%USERPROFILE%\.poetry` |
| `PYENV_ROOT` | 探测 `%USERPROFILE%\.pyenv\pyenv-win`、`%USERPROFILE%\.pyenv` |
| `ASDF_DIR` | 探测 `%USERPROFILE%\.asdf` |
| `ASDF_DATA_DIR` | 根据 `ASDF_DIR` 设置 |
| `RBENV_ROOT` / `NODENV_ROOT` / `GOENV_ROOT` / `JENV_ROOT` | 探测用户目录下对应 manager 根目录 |
| `NVM_DIR` | 默认 `%USERPROFILE%\.nvm` |
| `NVM_HOME` | 探测 `%APPDATA%\nvm`、Scoop nvm、用户 `.nvm` |
| `NVM_SYMLINK` | 探测 `%ProgramFiles%\nodejs` 和 Scoop nodejs |
| `SDKMAN_DIR` | 默认 `%USERPROFILE%\.sdkman`，但不 source init 脚本 |
| `JAVA_HOME` | 探测 `%ProgramFiles%` 下常见 JDK 目录 |
| `DOCKER_BUILDKIT` | 默认 `1` |
| `COMPOSE_DOCKER_CLI_BUILD` | 默认 `1` |
| `LF_ICONS` | 如果 `%XDG_CONFIG_HOME%\lf\icons` 存在，则读取该文件 |

不会执行：

- `mise activate` 或 `mise` hook
- `fnm env`
- `rbenv` / `nodenv` / `goenv` / `jenv` init hook
- `conda shell.powershell hook`
- `micromamba shell hook`
- `direnv hook`
- `starship init`
- `sdkman-init.ps1`

## PATH 处理

配置会清理当前进程的 `PATH`：

| 行为 | 说明 |
| --- | --- |
| 删除空段 | 处理连续 `;;` 或结尾 `;` |
| 只加入存在的目录 | 不把无效目录塞进 `PATH` |
| 忽略大小写去重 | 符合 Windows 路径语义 |
| 使用 `;` 分隔 | Windows PowerShell 5.1 专用 |

会尝试前置这些常见路径，如果它们存在：

```text
%USERPROFILE%\.cargo\bin
%USERPROFILE%\.rd\bin
%USERPROFILE%\.opencode\bin
%BUN_INSTALL%\bin
%DENO_INSTALL%\bin
%NPM_CONFIG_PREFIX%\bin
%PNPM_HOME%
%USERPROFILE%\.yarn\bin
%USERPROFILE%\.config\yarn\global\node_modules\.bin
%VOLTA_HOME%\bin
%USERPROFILE%\.volta\bin
%FNM_DIR%
%USERPROFILE%\.local\share\npm\bin
%PYENV_ROOT%\bin
%ANACONDA_HOME%\bin
%ANACONDA_HOME%\Scripts
%ANACONDA_HOME%\condabin
%POETRY_HOME%\bin
%USERPROFILE%\.poetry\bin
%USERPROFILE%\.local\pipx\bin
%GOPATH%\bin
%GOROOT%\bin
%USERPROFILE%\scoop\shims
%PROGRAMDATA%\scoop\shims
%PROGRAMDATA%\chocolatey\bin
%LOCALAPPDATA%\Microsoft\WindowsApps
%APPDATA%\npm
%USERPROFILE%\.nix-profile\bin
%USERPROFILE%\.mise\shims
%MISE_DATA_DIR%\shims
%ASDF_DIR%\bin
%ASDF_DATA_DIR%\shims
%PYENV_ROOT%\shims
%PYENV_ROOT%\pyenv-win\bin
%PYENV_ROOT%\pyenv-win\shims
%FNM_DIR%\aliases\default\bin
%NVM_HOME%
%NVM_SYMLINK%
%JAVA_HOME%\bin
%RBENV_ROOT%\bin
%RBENV_ROOT%\shims
%NODENV_ROOT%\bin
%NODENV_ROOT%\shims
%GOENV_ROOT%\bin
%GOENV_ROOT%\shims
%JENV_ROOT%\bin
%JENV_ROOT%\shims
```

会尝试后置这些用户路径，如果它们存在：

```text
%USERPROFILE%\.lmstudio\bin
%USERPROFILE%\.mimocode\bin
%USERPROFILE%\.local\bin
%USERPROFILE%\bin
%USERPROFILE%\Applications
%USERPROFILE%\.local\Applications
```

## PSReadLine

PSReadLine 默认只在交互式会话加载。可以用环境变量控制：

```powershell
$env:POWERSHELL_LOAD_PSREADLINE = '1'  # 强制加载
$env:POWERSHELL_LOAD_PSREADLINE = '0'  # 禁用
```

会按当前 PSReadLine 实际支持的参数设置：

| 设置 | 行为 |
| --- | --- |
| `EditMode` | `Vi` |
| `BellStyle` | `None` |
| `HistoryNoDuplicates` | `$true` |
| `HistorySearchCursorMovesToEnd` | `$true` |
| `MaximumHistoryCount` | `10000` |
| `HistorySaveStyle` | `SaveIncrementally` |
| `HistorySavePath` | `XDG_STATE_HOME\WindowsPowerShell\PSReadLineHistory.txt`，目录可用时设置 |
| `AddToHistoryHandler` | 支持时过滤包含 password/secret/token/api key 的敏感命令 |

PowerShell 7 预测相关参数不会设置：

```text
PredictionSource
PredictionViewStyle
```

按键绑定也做了兼容处理：只有在 `EditMode` 已经是 `Vi`，并且当前
`Set-PSReadLineKeyHandler` 支持 `-ViMode` 时，才会传入 `-ViMode`。这样可以避免：

```text
Set-PSReadLineOption : 找不到与参数名称“PredictionSource”匹配的参数。
警告: 使用了 -ViMode 参数，但当前 EditMode 不是 Vi。
```

## Prompt

`dot_config/powershell/conf.d/90-prompt.ps1` 中依赖外部命令的部分没有迁移：

- 不调用 `starship init`。
- 不调用 `git`。
- 不执行 zoxide hook。

5.1 版本迁移了 fallback prompt 的内置部分：

| Prompt 内容 | 5.1 支持情况 |
| --- | --- |
| 当前时间 | 支持 |
| `user@host` | 支持 |
| 当前路径 | 支持，用户目录会显示成 `~` |
| `VIRTUAL_ENV` | 支持，显示虚拟环境目录名 |
| `CONDA_DEFAULT_ENV` | 支持，非 `base` 时显示 |
| Git 分支 | 支持，通过读取 `.git\HEAD`，不调用 `git` |
| Git dirty 状态 | 不支持 |
| 上一条命令失败码 | 支持 |
| ANSI 颜色 | 支持，使用 `[char]27`，不使用 PowerShell 7 的 `` `e`` |

Git dirty 状态没有迁移，因为准确判断需要执行 `git diff-index`。5.1 配置只读取 `.git\HEAD`，可显示普通仓库、worktree/submodule gitdir 文件指向的分支；detached HEAD 会显示短 hash。

## 内置函数

| 函数 | 功能 | 是否需要外部工具 |
| --- | --- | --- |
| `ll` | `Get-ChildItem -Force` | 否 |
| `la` | `Get-ChildItem -Force` | 否 |
| `l` | `Get-ChildItem` | 否 |
| `lt` | 按 `LastWriteTime` 倒序列出文件 | 否 |
| `..` | 返回上级目录 | 否 |
| `...` | 返回上两级目录 | 否 |
| `....` | 返回上三级目录 | 否 |
| `mkdirp` | 创建目录，自动创建父目录 | 否 |
| `now` | 输出时间戳 | 否 |
| `reload` | 重新加载当前 `config.ps1` | 否 |
| `grep` | `Select-String` 简单包装 | 否 |
| `mkcd` | 创建并进入目录 | 否 |
| `paths` | 输出当前 `PATH` 条目 | 否 |
| `proxy` | 设置 HTTP/HTTPS 代理环境变量 | 否 |
| `socks5` | 设置 SOCKS 代理环境变量 | 否 |
| `unproxy` | 清理代理环境变量 | 否 |
| `proxyinfo` | 查看代理环境变量 | 否 |
| `uuid` | 生成 UUID v4 | 否 |
| `randstr` | 生成随机字符串 | 否 |
| `prompt` | 时间、user@host、路径、venv/conda、git 分支、失败码提示符 | 否 |

`uuid`、`randstr`、`mkcd` 有基础参数补全。

## 与跨平台版本对比

| 功能 / 区域 | `dot_config/powershell` 跨平台版 | `Documents/WindowsPowerShell` 5.1 版 | 5.1 状态 | 原因 |
| --- | --- | --- | --- | --- |
| 主入口 | `config.ps1` 动态加载子目录 | 单文件 `config.ps1` | 改造 | 避免加载 7+ 或外部工具脚本 |
| profile 包装 | `Microsoft.PowerShell_profile.ps1`、`profile.ps1` | 同名文件 | 保留 | 原生 profile 入口 |
| `functions/*.ps1` | 自动加载 | 不扫描 | 删除 | 保持 5.1 启动可控 |
| `conf.d/*.ps1` | 自动加载 | 不扫描 | 删除 | 多数包含跨平台或外部工具逻辑 |
| `completions/*.ps1` | 自动加载 | 不扫描 | 删除 | 仅保留内联基础补全 |
| XDG 变量 | 支持 | 支持 | 保留 | 内置 API 可实现 |
| OS 检测 | Windows/Linux/macOS/WSL | 固定 Windows | 改造 | Windows PowerShell 5.1 只面向 Windows |
| `SHELLS_OS` | 按平台设置 | 固定 `windows` | 改造 | Windows 专用 |
| `EDITOR` | 默认 `vim` | 默认 `notepad.exe` | 改造 | 避免依赖外部编辑器 |
| `PAGER` / `LESS` | 设置 | 不设置 | 删除 | `less` 不是 Windows 内置 |
| `.envs` | 支持 | 支持 | 保留 | 内置文件和环境变量 API |
| `.envs` PATH 分隔 | Windows 用 `;`，Unix 用 `:`/`;` | 只用 `;` | 改造 | Windows 专用 |
| PATH 去重 | 支持 | 支持 | 保留 | 修复空段和重复路径 |
| Unix PATH | Linux/macOS/Homebrew/Nix 等 | 不加入 | 删除 | Windows PowerShell 不适用 |
| Windows PATH | Scoop/Chocolatey/WindowsApps/npm | Scoop/Chocolatey/WindowsApps/npm | 保留 | Windows 常用路径 |
| Homebrew 检测 | 支持 | 不支持 | 删除 | 非 Windows 原生 |
| toolchain 环境变量 | npm/pnpm/mise/fnm/go/pyenv/asdf 等 | 静态环境变量已迁移 | 改造 | 只设置变量，不执行外部 hook |
| `$PSStyle` | PowerShell 7 输出渲染 | 不使用 | 删除 | 5.1 没有 `$PSStyle` |
| PSReadLine 加载 | 交互式加载 | 交互式加载 | 保留 | 5.1 可用 |
| PSReadLine 历史 | 支持 | 按可用参数设置 | 保留 | 兼容不同 PSReadLine 版本 |
| PSReadLine 预测 | `PredictionSource` / `PredictionViewStyle` | 不设置 | 删除 | 5.1 常见 PSReadLine 不支持 |
| PSReadLine Vi 键位 | 直接使用 `-ViMode` | 只在 Vi 模式启用后使用 | 改造 | 避免启动警告 |
| 敏感历史过滤 | `AddToHistoryHandler` | 支持时启用 | 保留 | 参数不一定存在 |
| 默认别名 | `ll`、`la`、`l`、`lt`、`..` 等 | 核心别名和 `mkdirp` | 保留 | 全部内置实现 |
| `.aliases` | 支持 | 支持 | 保留 | 本地用户自定义 |
| `.aliases` 缓存 | 有缓存文件 | 无缓存 | 简化 | 5.1 版本保持简单 |
| `mkcd` | 独立函数文件 | 内联函数 | 保留 | 内置命令可实现 |
| `paths` | 独立函数文件 | 内联函数 | 保留 | 内置命令可实现 |
| `proxy` 系列 | 独立函数文件 | 内联函数 | 保留 | 只改环境变量 |
| `uuid` | 独立函数文件 | 内联函数 | 保留 | `[guid]::NewGuid()` 可用 |
| `randstr` | 使用较新的 .NET API | 使用 .NET Framework 兼容 RNG | 改造 | 5.1 没有 `RandomNumberGenerator.GetInt32()` |
| `github` | 支持 | 不包含 | 删除 | 涉及网络/API 和可选 `jq` |
| `mcc` | 支持 | 不包含 | 删除 | 不是最小内置启动配置 |
| `spm` | 包管理器包装 | 不包含 | 删除 | 依赖大量外部包管理器 |
| `fzf` | 支持 | 不包含 | 删除 | 依赖 `fzf`、`fd`、`bat` |
| `zoxide` | 支持 | 不包含 | 删除 | 依赖 `zoxide` |
| `lf` | 支持 | 只读取 `LF_ICONS` | 精简 | 不包装外部 `lf` 命令 |
| `yazi` | 支持 | 不包含 | 删除 | 依赖 `yazi` |
| `mise` | 支持命令包装 | 设置 `MISE_DATA_DIR` 和 shims PATH | 精简 | 不执行 `mise` hook |
| `asdf` | 路径和集成 | 设置 `ASDF_DIR`、`ASDF_DATA_DIR` 和 PATH | 精简 | 不执行外部 init |
| `pyenv` | 路径和集成 | 设置 `PYENV_ROOT` 和 pyenv-win PATH | 精简 | 不执行外部 init |
| `fnm` | 支持 hook | 设置 `FNM_DIR` 和默认 node PATH | 精简 | 不执行 `fnm env` |
| `nvm` | 支持 Windows 路径 | 设置 `NVM_DIR`、`NVM_HOME`、`NVM_SYMLINK` 和 PATH | 精简 | 不调用 nvm |
| `conda` / `micromamba` | 支持 hook 和函数包装 | 设置 `ANACONDA_HOME` 和 conda PATH | 精简 | 不执行 conda/micromamba hook |
| `SDKMAN` | 支持 init 脚本 | 只设置 `SDKMAN_DIR` | 精简 | 不 source `sdkman-init.ps1` |
| `direnv` | 支持 | 不包含 | 删除 | 依赖 `direnv` 和 hook |
| `poetry` 补全 | 支持 | 设置 `POETRY_HOME` 和 PATH，不加载补全 | 精简 | 避免加载外部生成脚本 |
| 插件系统 | git-backed 插件安装/更新 | 不包含 | 删除 | 依赖 `git` 和网络 |
| Starship prompt | 支持 | 不包含 | 删除 | 依赖 `starship` 初始化 |
| fallback prompt | 时间、user@host、路径、venv/conda、git、退出码 | 内置 fallback 已迁移 | 改造 | 不调用外部命令 |
| git 分支/dirty 状态 | 调用 `git` 显示分支和 dirty | 读取 `.git\HEAD` 显示分支，不显示 dirty | 精简 | dirty 判断需要外部 `git` |
| 参数补全 | 多个补全文件 | `uuid`、`randstr`、`mkcd` | 精简 | 保留内置子集 |
| 外部命令发现 | 多处 `Get-Command` 查找工具 | 只查 PSReadLine cmdlet/module | 精简 | 不做外部工具 hook |
| `Invoke-Expression` hook | 用于工具生成的初始化脚本 | 不使用 | 删除 | 避免外部生成脚本执行 |
| 自动安装 | 可用 git clone 插件 | 不支持 | 删除 | 避免网络和 `git` 依赖 |

## 验证

可以在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\Documents\WindowsPowerShell\config.ps1"
```

强制加载 PSReadLine：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:POWERSHELL_LOAD_PSREADLINE='1'; . .\Documents\WindowsPowerShell\config.ps1"
```

预期结果：

- 不出现 `PredictionSource` 参数错误。
- 不出现 `-ViMode` 相关警告。
- `.envs`、`.aliases` 不存在时静默跳过。
- 状态目录无法创建时不影响启动。

## chezmoi 应用

修改源目录后应用到真实 profile 目录：

```powershell
chezmoi apply
```

目标路径通常是：

```text
%USERPROFILE%\Documents\WindowsPowerShell
```
