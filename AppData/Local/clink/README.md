# Clink/cmd 配置

这个目录是 `cmd.exe` 的 Clink 配置，目标是把 `dot_config/powershell`
中能用 Clink 内置能力实现的部分迁移过来。

重要边界：这个版本不能做到和 PowerShell 完全一样。Clink 运行在 `cmd.exe`
前面，能增强编辑、补全、提示符和输入过滤，但不能提供 PowerShell 的对象管道、
函数参数绑定、模块系统、PSReadLine 语义或 PowerShell provider。

## 文件结构

```text
AppData/Local/clink/
  00-shells-core.lua
  10-shells-env.lua
  40-shells-commands.lua
  90-shells-prompt.lua
  starship.lua
  README.md
```

| 文件 | 作用 |
| --- | --- |
| `00-shells-core.lua` | 公共 helper、PATH 处理、Clink 错误码设置 |
| `10-shells-env.lua` | `.envs`、开发环境变量、PATH 迁移 |
| `40-shells-commands.lua` | 用 `clink.onfilterinput()` 实现 Clink 原生命令 |
| `90-shells-prompt.lua` | Clink fallback prompt |
| `starship.lua` | 明确禁用 starship 外部初始化 |

flexprompt 相关脚本不保留。这样不会再出现：

```text
Flexprompt has not yet been configured.
Run "flexprompt configure" to configure the prompt.
```

## 约束

本配置只使用：

- Clink Lua API，例如 `os.setenv()`、`os.chdir()`、`os.mkdir()`、
  `os.findfiles()`、`os.createguid()`、`clink.promptfilter()`、
  `clink.onfilterinput()`。
- Lua 内置能力，例如 `io.open()` 读取文本文件、`string`、`table`、`os.date()`。

本配置不会调用：

- `powershell.exe` / `pwsh.exe`
- `git.exe`
- `starship`
- `fzf` / `fd` / `bat`
- `zoxide`
- `mise` / `fnm` / `conda` / `micromamba` / `direnv` 等 hook
- `doskey.exe`
- `cmd /c`

`.aliases` 会用 Clink 内置 `os.setalias()` 注册为 doskey 宏。注册宏本身不执行
alias body；如果 alias body 写的是外部命令，只有用户手动运行该 alias 时才会执行。

`40-aliases.ps1` 迁移来的 `l`、`ll`、`..`、`md`、`cls` 等命令会被 Clink
重写成当前 `cmd.exe` 的内置命令，例如 `dir`、`cd`、`mkdir`、`cls`。这些不是外部
程序，也不会启动新的进程；目录切换必须这样做，才能真正改变当前 cmd 会话的目录。

## 启动行为

启动时设置：

| 项目 | 行为 |
| --- | --- |
| `SHELLS_OS` | 固定为 `windows` |
| `SHELLS_CLINK` | 固定为 `1` |
| `XDG_CONFIG_HOME` | 默认 `%USERPROFILE%\.config` |
| `XDG_DATA_HOME` | 默认 `%USERPROFILE%\.local\share` |
| `XDG_STATE_HOME` | 默认 `%USERPROFILE%\.local\state` |
| `XDG_CACHE_HOME` | 默认 `%USERPROFILE%\.cache` |
| `EDITOR` | 默认 `notepad.exe` |
| `VISUAL` | 默认跟随 `EDITOR` |
| `CLICOLOR` | 默认 `1` |
| `cmd.get_errorlevel` | 通过 Clink setting 启用，供 prompt 显示上一条命令错误码 |

## `.envs`

默认读取：

```text
%USERPROFILE%\.envs
```

也可以通过环境变量指定：

```text
CLINK_LOCAL_ENVS_FILE=C:\path\to\envs
```

兼容读取旧变量：

```text
POWERSHELL_LOCAL_ENVS_FILE=C:\path\to\envs
```

支持格式：

```text
FOO=bar
export BAR=baz
PATH={HOME}\bin;{PATH}
```

规则：

| 规则 | 说明 |
| --- | --- |
| 空行和 `#` 开头行 | 忽略 |
| `export ` 前缀 | 支持 |
| 变量名 | 必须匹配 `^[A-Za-z_][A-Za-z0-9_]*$` |
| 外层引号 | 成对单引号或双引号会去掉 |
| `{HOME}` | 替换为用户主目录 |
| `{PATH}` | 替换为当前进程 `PATH` |
| `PATH` | 按 Windows `;` 分隔，只加入已经存在的目录 |

## `.aliases`

默认读取：

```text
%USERPROFILE%\.aliases
```

也可以通过环境变量指定：

```text
CLINK_LOCAL_ALIASES_FILE=C:\path\to\aliases
```

兼容读取旧变量：

```text
POWERSHELL_LOCAL_ALIASES_FILE=C:\path\to\aliases
```

示例：

```text
gs=git status
home=cd /d %USERPROFILE%
e=notepad.exe
```

规则：

| 规则 | 说明 |
| --- | --- |
| 每行格式 | `NAME=BODY` |
| 空行和 `#` 开头行 | 忽略 |
| 名称 | 必须匹配 `^[A-Za-z_][A-Za-z0-9_.-]*$` |
| 外层引号 | 成对单引号或双引号会去掉 |
| 参数传递 | 如果 body 没有 `$*` 或 `$1`..`$9`，自动追加 `$*` |
| 执行时机 | 启动时只注册宏，不执行 body |

注意：`.aliases` 在 Clink/cmd 下必须写 doskey/cmd 语法，不是 PowerShell 语法。
PowerShell 写法例如 `Get-ChildItem -Force`、`@args`、管道对象属性等不能直接通用。

## 开发环境变量

已迁移静态环境变量和目录探测：

| 环境变量 | 行为 |
| --- | --- |
| `NPM_CONFIG_PREFIX` | 默认 `%USERPROFILE%\.npm-global` |
| `PNPM_HOME` | 默认 `%USERPROFILE%\.pnpm-global` |
| `MISE_DATA_DIR` | 默认 `%XDG_DATA_HOME%\mise` |
| `GOPATH` | 默认 `%USERPROFILE%\go` |
| `NVM_DIR` | 默认 `%USERPROFILE%\.nvm` |
| `SDKMAN_DIR` | 默认 `%USERPROFILE%\.sdkman` |
| `DOCKER_BUILDKIT` | 默认 `1` |
| `COMPOSE_DOCKER_CLI_BUILD` | 默认 `1` |
| `FNM_DIR` | 探测 `%XDG_DATA_HOME%\fnm`、`%USERPROFILE%\.fnm` |
| `VOLTA_HOME` | 探测 `%USERPROFILE%\.volta` |
| `BUN_INSTALL` | 探测 `%USERPROFILE%\.bun` |
| `DENO_INSTALL` | 探测 `%USERPROFILE%\.deno` |
| `GOROOT` | 探测用户目录、`LOCALAPPDATA`、`ProgramFiles`、`C:\Go` |
| `ANACONDA_HOME` | 探测用户目录、`LOCALAPPDATA`、`PROGRAMDATA` 下的 conda 目录 |
| `POETRY_HOME` | 探测 `%USERPROFILE%\.poetry` |
| `PYENV_ROOT` | 探测 `%USERPROFILE%\.pyenv\pyenv-win`、`%USERPROFILE%\.pyenv` |
| `ASDF_DIR` | 探测 `%USERPROFILE%\.asdf` |
| `ASDF_DATA_DIR` | 根据 `ASDF_DIR` 设置 |
| `RBENV_ROOT` / `NODENV_ROOT` / `GOENV_ROOT` / `JENV_ROOT` | 探测用户目录下对应 manager 根目录 |
| `NVM_HOME` | 探测 `%APPDATA%\nvm`、Scoop nvm、用户 `.nvm` |
| `NVM_SYMLINK` | 探测 `%ProgramFiles%\nodejs` 和 Scoop nodejs |
| `JAVA_HOME` | 探测 `%ProgramFiles%` 下常见 JDK 目录 |
| `LF_ICONS` | 如果 `%XDG_CONFIG_HOME%\lf\icons` 存在，则读取该文件 |

不会执行任何 init hook。也就是说这些工具的可执行文件可能通过 PATH 可见，但 shell
启动时不会自动激活版本、环境或目录 hook。

## PATH

PATH 处理规则：

| 行为 | 说明 |
| --- | --- |
| 删除空段 | 处理连续 `;;` 或结尾 `;` |
| 只加入存在的目录 | 不把无效目录塞进 `PATH` |
| 忽略大小写去重 | 符合 Windows 路径语义 |
| 使用 `;` 分隔 | cmd/Windows 专用 |

迁移了 Windows PowerShell 5.1 版本中的常见路径，包括用户 `bin`、Cargo、Bun、
Deno、npm/pnpm/yarn、Volta、fnm、pyenv、conda、Poetry、pipx、Go、Scoop、
Chocolatey、WindowsApps、nix、mise/asdf shims、NVM、Java、rbenv/nodenv/goenv/jenv
等目录。目录不存在时会跳过。

## Clink 原生命令

这些命令由 `clink.onfilterinput()` 处理。能纯 Lua 完成的命令直接在 Clink 中执行；
需要改变 cmd 会话状态或使用 cmd 内置行为的命令，会被重写成当前 cmd 的内置命令：

| 命令 | 功能 | 实现 |
| --- | --- | --- |
| `l [pattern]` | 列出文件和目录 | 重写为 cmd 内置 `dir` |
| `ll [pattern]` | 列出全部文件和目录 | 重写为 cmd 内置 `dir /a` |
| `la [pattern]` | 同 `ll` | 重写为 cmd 内置 `dir /a` |
| `lt [pattern]` | 按修改时间倒序列出 | 重写为 cmd 内置 `dir /a /o-d` |
| `..` / `...` / `....` | 跳到上级目录 | 重写为 cmd 内置 `cd /d` |
| `md <dir...>` | 递归创建目录 | 重写为 cmd 内置 `mkdir` |
| `mkdirp <dir...>` | 递归创建目录 | 重写为 cmd 内置 `mkdir` |
| `mkcd <dir>` | 创建并进入目录 | 重写为 cmd 内置 `mkdir` + `cd /d` |
| `now` | 输出当前时间 | `os.date()` |
| `paths` | 输出 PATH 条目 | `os.getenv()` |
| `cls` / `clear` | 清屏 | 重写为 cmd 内置 `cls` |
| `proxy [host] [port]` | 设置 HTTP/HTTPS 代理变量 | `os.setenv()` |
| `socks5 [host] [port]` | 设置 SOCKS 代理变量 | `os.setenv()` |
| `unproxy` | 清空代理变量 | `os.setenv(name, "")` |
| `proxyinfo` | 查看代理变量 | `os.getenv()` |
| `uuid [-n COUNT]` | 生成 UUID | `os.createguid()` |
| `randstr` | 生成随机字符串 | `os.createguid()` 派生字符 |
| `grep LUA_PATTERN [file...]` | 简单文本搜索 | Lua `io.open()` 和 Lua pattern |

限制：

- 这些命令只在整行命令中生效；如果输入里包含 `|`、`&`、`<`、`>`，会交给 cmd。
- `grep` 使用 Lua pattern，不是 PowerShell regex，也不是 GNU grep regex。
- `randstr` 使用 Clink `os.createguid()` 作为随机来源，不调用外部随机工具。
- `unproxy` 通过把变量设为空字符串实现；对大多数命令等价于未设置。
- PowerShell 里的 `reload` 没有迁移；Clink/cmd 配置变更后重新打开 `cmd.exe` 最干净。

## Prompt

Prompt 迁移了 `dot_config/powershell/conf.d/90-prompt.ps1` fallback 部分中不依赖外部
命令的内容：

| Prompt 内容 | Clink 支持情况 |
| --- | --- |
| 当前时间 | 支持 |
| `user@host` | 支持 |
| 当前路径 | 支持，用户目录显示为 `~` |
| `VIRTUAL_ENV` | 支持，显示虚拟环境目录名 |
| `CONDA_DEFAULT_ENV` | 支持，非 `base` 时显示 |
| Git 分支 | 支持，直接读 `.git\HEAD` |
| detached HEAD | 支持，显示短 hash |
| worktree/submodule gitdir 文件 | 支持 |
| Git dirty 状态 | 不支持 |
| 上一条命令错误码 | 支持，依赖 Clink `cmd.get_errorlevel` |
| ANSI 颜色 | 支持，可用 `NO_COLOR=1` 禁用 |

Git dirty 状态没有迁移，因为准确判断需要执行 `git status` 或 `git diff-index`。

## 与 PowerShell 跨平台版对比

| 功能 / 区域 | `dot_config/powershell` | Clink/cmd 版 | 状态 | 原因 |
| --- | --- | --- | --- | --- |
| 主入口 | `config.ps1` 加载 `functions/conf.d/completions` | 多个 `.lua` 文件按名称加载 | 改造 | Clink 使用 Lua 脚本模型 |
| Shell 语言 | PowerShell | cmd + Clink Lua | 不等价 | 语言和运行时不同 |
| 对象管道 | 支持对象流 | 不支持 | 删除 | cmd 只有文本命令行 |
| PowerShell 函数 | 支持高级函数和参数绑定 | 只支持 Clink 输入拦截命令 | 改造 | Clink 不能定义 PowerShell 函数 |
| PowerShell 模块 | 支持 | 不支持 | 删除 | Clink 不能加载 PowerShell 模块 |
| PSReadLine | 支持 | Clink 自带 readline 能力 | 替代 | API 和键位语义不同 |
| 参数补全 | `Register-ArgumentCompleter` | 保留 Clink 默认补全 | 精简 | 未迁移 PowerShell AST 补全 |
| XDG 变量 | 支持 | 支持 | 保留 | `os.setenv()` 可实现 |
| `.envs` | 支持 | 支持 | 保留 | Lua 文件读取可实现 |
| `.aliases` | 生成 PowerShell 函数 | 注册 doskey 宏 | 改造 | 语法必须改为 cmd/doskey |
| PATH 去重 | 支持 | 支持 | 保留 | Lua 可实现 |
| Windows 开发 PATH | 支持 | 支持 | 保留 | 只检查目录，不执行命令 |
| Unix PATH | Linux/macOS/Homebrew 等 | 不加入 | 删除 | cmd 只面向 Windows |
| npm/pnpm/Go/Java/pyenv 等变量 | 支持 | 静态变量和 PATH 支持 | 保留 | 不需要外部命令 |
| mise | hook/shims | 只设置 `MISE_DATA_DIR` 和 shims PATH | 精简 | 不执行 `mise` |
| fnm | hook | 只设置 `FNM_DIR` 和默认 alias PATH | 精简 | 不执行 `fnm` |
| nvm-windows | PATH 支持 | `NVM_HOME` / `NVM_SYMLINK` PATH 支持 | 保留 | 不调用 nvm |
| conda/micromamba | hook | 只设置 `ANACONDA_HOME` 和 PATH | 精简 | 不执行 shell hook |
| asdf/rbenv/nodenv/goenv/jenv | init/hook + PATH | 只设置 root 和 shims PATH | 精简 | 不执行 init |
| SDKMAN | source init 脚本 | 只设置 `SDKMAN_DIR` | 精简 | 不执行脚本 |
| direnv | hook | 不支持 | 删除 | 需要外部 `direnv` |
| zoxide | hook/function | 不支持 | 删除 | 需要外部 `zoxide` |
| fzf/fd/bat | 集成 | 不支持 | 删除 | 需要外部程序 |
| lf/yazi 包装 | 支持 | 只保留 `LF_ICONS` 读取 | 精简 | 不执行外部文件管理器 |
| starship | 可初始化 | 禁用 | 删除 | 需要外部 `starship` |
| fallback prompt | 时间、用户、路径、venv、git、错误码 | 支持内置子集 | 改造 | Git 只读 `.git\HEAD` |
| Git dirty 状态 | 可调用 git 判断 | 不支持 | 删除 | 需要外部 `git` |
| `ll/la/l/lt` | PowerShell `Get-ChildItem` | 重写为 cmd 内置 `dir` | 改造 | 需要让当前 cmd 会话执行内置列目录命令 |
| `md/mkdirp/mkcd` | PowerShell `New-Item` | 重写为 cmd 内置 `mkdir` / `cd` | 改造 | Clink Lua `os.chdir()` 不能可靠改变当前 cmd 会话目录 |
| `proxy/socks5/unproxy` | 环境变量函数 | Clink 原生命令 | 保留 | `os.setenv()` 可实现 |
| `uuid` | `[guid]::NewGuid()` | `os.createguid()` | 保留 | Clink 内置 GUID API |
| `randstr` | .NET RNG | `os.createguid()` 派生 | 改造 | 不调用外部随机工具 |
| `grep` | `Select-String` | Lua pattern 搜索 | 精简 | 没有 PowerShell regex 引擎 |
| `github` / `mcc` / `spm` | PowerShell 函数 | 不支持 | 删除 | 涉及外部命令、网络或 PowerShell |
| 插件系统 | 可用 git/网络安装 | 不支持 | 删除 | 不能调用外部程序 |

## 验证

静态检查时应确认新增脚本里没有这些调用：

```text
io.popen
os.execute
cmd /c
powershell
pwsh
starship init
```

应用 chezmoi 后重新打开 `cmd.exe`，应看到 Shells prompt，并且不会加载 flexprompt。
