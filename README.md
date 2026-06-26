# Chezmoi Dotfiles

这是一个使用 [chezmoi](https://www.chezmoi.io/) 管理的个人 dotfiles 仓库，用来在多台机器之间同步终端环境配置。敏感文件通过 GPG 对称加密保存，适合把 SSH 配置、私钥等内容放进仓库但不暴露明文。


# 如何使用 git worktree 进行管理开发
## 克隆裸项目
```bash
mkdir -p ~/code/dotfiles/chezmoi-cfgs
cd ~/code/dotfiles/chezmoi-cfgs
git clone git@github.com:lgf5090/chezmoi-cfgs.git --bare .git
```

## 添加main主分支的worktree
```bash
# 不要在里面修改任何代码，主要功能是拉取最新代码
git worktree add ./main
```

## 添加dev和test分支
```bash
git worktree add -b dev ./dev
git worktree add -b test ./test
cd dev && git push -u origin dev cd ..
cd test && git push -u origin test && cd ..
```


## 软件安装详细文档
### winget
[winget_install_list](docs/winget_install_list.md)

### npm 
[ai_cli_install_list](docs/ai_cli_install_list.md)



## 主要内容

```text
.
├── .chezmoi.toml.tmpl
├── dot_bashrc
├── dot_zshrc
├── dot_config/
│   ├── bash/
│   ├── zsh/
│   ├── nushell/
│   └── powershell/
└── dot_ssh/
```

- `dot_bashrc`、`dot_zshrc`：轻量入口，只负责加载 `~/.config/bash/config.bash` 和 `~/.config/zsh/config.zsh`。
- `dot_config/{bash,zsh,nushell,powershell}`：按 `functions/`、`conf.d/`、`completions/` 分层组织 shell 配置。
- `dot_ssh/`：加密后的 SSH 文件，例如私钥、known_hosts、config。
- `.chezmoi.toml.tmpl`：生成本机 `chezmoi.toml`，当前启用 GPG 对称加密。

## 前置依赖

最小依赖：
### windows
```powershell
winget install twpayne.chezmoi Chocolatey.Chocolatey Devolutions.UniGetUI Atuinsh.Atuin marlocarlo.psmux marlocarlo.psnet marlocarlo.pstop Helvesec.RMUX vim.vim Neovim.Neovim Neovide.Neovide Helix.Helix Microsoft.Edit zyedidia.micro Microsoft.PowerShell Microsoft.WindowsTerminal Microsoft.VisualStudioCode Microsoft.VisualStudioCode.Insiders 7zip.7zip Git.Git Microsoft.Coreutils junegunn.fzf JFLarvoire.Ag ajeetdsouza.zoxide Schniz.fnm sxyazi.yazi yorukot.superfile gokcehan.lf BurntSushi.ripgrep.MSVC jqlang.jq JesseDuffield.lazygit sharkdp.bat Microsoft.PowerToys voidtools.Everything zTools.zTools Obsidian.Obsidian codexu.NoteGen Logseq.Logseq Joplin.Joplin wez.wezterm.nightly kangfenmao.CherryStudio Bin-Huang.Chatbox NickeManarin.ScreenToGif VideoLAN.VLC Daum.PotPlayer Starpine.Screenbox PeterPawlowski.foobar2000 Alacritty.Alacritty Mobatek.MobaXterm Zellij.Zellij Fastfetch-cli.Fastfetch Warp.Warp 
```


### unix

```bash
sudo apt update
sudo apt install -y bash zsh git gnupg
```

还需要安装 chezmoi：

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)"
```

按需安装这些工具，否则对应配置会自动跳过或使用降级逻辑：

```text
nu / pwsh / starship / fzf / zoxide / lf / nvm / git
```

Nushell 自动加载文件由 `config.nu` 在 Nushell 启动时生成，不依赖 chezmoi 脚本。

## 首次安装

```bash
chezmoi init --apply https://github.com/lgf5090/chezmoi-cfgs.git
```

这条命令会做三件事：

1. 克隆仓库到 `~/.local/share/chezmoi`。
2. 根据 `.chezmoi.toml.tmpl` 生成本机 `~/.config/chezmoi/chezmoi.toml`。
3. 把仓库里的 dotfiles 应用到 `$HOME`。

首次安装时会提示输入一次 `GPG passphrase`。这个密码会写入本机 `~/.config/chezmoi/chezmoi.toml`，后续解密多个 GPG 对称加密文件时会自动复用，避免同一次 `apply` 里反复输入。

安装后可以检查：

```bash
chezmoi verify
ls -la ~/.ssh
```

## 日常工作流

查看将要修改什么：

```bash
chezmoi diff
```

应用所有配置：

```bash
chezmoi apply
```

只预览，不写入：

```bash
chezmoi apply --dry-run --verbose
```

编辑源文件后应用：

```bash
chezmoi edit ~/.bashrc
chezmoi apply ~/.bashrc
```

把 `$HOME` 里手动改过的文件同步回仓库：

```bash
chezmoi re-add ~/.bashrc
```

拉取远端更新并应用：

```bash
chezmoi update -v
```

## 精确使用 `chezmoi apply`

`chezmoi apply` 的参数是目标路径，也就是最终落到 `$HOME` 里的路径。

应用单个文件：

```bash
chezmoi apply ~/.bashrc
chezmoi apply ~/.config/nushell/config.nu
```

应用整个目录：

```bash
chezmoi apply ~/.config/bash
chezmoi apply ~/.config/nushell
```

同时应用多个目标：

```bash
chezmoi apply ~/.bashrc ~/.zshrc ~/.config/nushell
```

如果更习惯使用仓库里的 source path，可以加 `--source-path`：

```bash
chezmoi apply --source-path dot_bashrc
chezmoi apply --source-path dot_config/nushell
```

临时“排除某个目录”时，推荐反过来只指定要应用的目录或文件。例如想更新 shell 配置但不碰 `~/.ssh`：

```bash
chezmoi apply ~/.bashrc ~/.zshrc ~/.config/bash ~/.config/zsh ~/.config/nushell ~/.config/powershell
```

`--include` 和 `--exclude` 过滤的是 chezmoi 条目类型，不是任意目录或 glob。常用例子：

```bash
# 跳过加密文件，避免触发 GPG 解密提示
chezmoi apply --exclude=encrypted

# 跳过脚本，只应用文件、目录、符号链接等普通条目
chezmoi apply --exclude=scripts

# 只处理普通文件和目录
chezmoi apply --include=files,dirs

# 预览时也可以使用同样的过滤
chezmoi diff --exclude=encrypted
```

如果要长期在某台机器忽略某些 source path，应使用 `.chezmoiignore` 或模板条件，而不是依赖 `apply` 的临时参数。

## Nushell 自动加载

Nushell 的 `source` 是 parse-time 关键字，不能像 bash/zsh 那样在运行时循环目录并动态 `source` 一批文件。因此本仓库采用“`config.nu` 生成静态加载器”的方式：

1. Nushell 启动时加载 `config.nu`。
2. `config.nu` 用内置 `glob` 枚举 `completions/`、`functions/`、`conf.d/`。
3. `config.nu` 写入 `auto-generate-autoload.nu` 到 `$nu.data-dir/vendor/autoload`。
4. 下次 `nu` 启动时自动加载该文件。

常见生成位置：

```text
$nu.data-dir/vendor/autoload/auto-generate-autoload.nu
```

生成的加载顺序固定为：

```text
completions/*.nu
functions/*.nu
conf.d/*.nu
```

注意事项：

- 新增、删除、重命名 `dot_config/nushell/**/*.nu` 后，运行 `exec nu` 即可刷新 autoload 文件。
- 不需要手动修改 `auto-generate-autoload.nu`，它由 `config.nu` 自动生成。
- `conf.d/` 依赖文件名排序加载，继续使用 `00-`、`10-`、`90-` 这类前缀控制顺序。
- completion 会先于 function 加载，避免函数引用 completion 时找不到定义。
- `config.nu` 会创建 `zz-local-aliases.nu` 占位文件；`conf.d/45-local-aliases.nu` 会根据 `~/.aliases` 刷新它，让本地 alias 在
  `auto-generate-autoload.nu` 之后加载。

## 添加普通配置

添加不敏感文件：

```bash
chezmoi add ~/.gitconfig
chezmoi apply ~/.gitconfig
```

添加整个目录：

```bash
chezmoi add --recursive ~/.config/some-tool
chezmoi apply ~/.config/some-tool
```

提交变更：

```bash
git -C ~/.local/share/chezmoi status
git -C ~/.local/share/chezmoi add .
git -C ~/.local/share/chezmoi commit -m "Add some-tool config"
git -C ~/.local/share/chezmoi push
```

## 添加或更新敏感文件

本仓库使用 GPG 对称加密：

```toml
{{ $passphrase := promptStringOnce . "passphrase" "GPG passphrase" -}}

encryption = "gpg"

[data]
    passphrase = "..."

[gpg]
    symmetric = true
    args = ["--batch", "--passphrase", "...", "--no-symkey-cache"]
```

添加 SSH 私钥：

```bash
chezmoi add --encrypt ~/.ssh/id_rsa
```

递归添加 SSH 目录：

```bash
chezmoi add --encrypt --recursive ~/.ssh
```

查看仓库中的加密文件：

```bash
ls ~/.local/share/chezmoi/dot_ssh/
```

提交：

```bash
git -C ~/.local/share/chezmoi add dot_ssh/
git -C ~/.local/share/chezmoi commit -m "Update SSH files"
```

注意：GPG 对称加密密码无法找回。忘记密码后，只能删除旧加密文件并重新加密。

## 常见问题

### GPG 密码保存在哪里？

首次 `chezmoi init` 会通过 `.chezmoi.toml.tmpl` 提示一次 `GPG passphrase`，并把它写入本机配置：

```text
~/.config/chezmoi/chezmoi.toml
```

这是为了让 `chezmoi apply` 解密多个 `encrypted_*.asc` 文件时只输入一次密码。代价是该密码会以明文保存在本机，所以这个方案只适合自己的可信机器。

已有安装在拉取到这次模板变更后，可以重新生成本机配置：

```bash
chezmoi init --prompt
```

`--prompt` 会强制重新询问 `GPG passphrase` 并更新 `~/.config/chezmoi/chezmoi.toml`。

如果不想在某次操作里触碰加密文件，可以临时跳过：

```bash
chezmoi apply --exclude=encrypted
```

### 为什么不能直接管理 `~/.config/chezmoi/chezmoi.toml`？

chezmoi 不建议直接把自己的运行配置作为普通目标文件管理。跨机器差异应放在 `.chezmoi.toml.tmpl` 里，通过模板生成本机配置。

### 新机器上 SSH 权限不正确怎么办？

可以手动修正：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/config
```

如果经常遇到这个问题，可以新增 `run_once_` 脚本自动修正权限。

### 如何确认某个 source path 会落到哪里？

```bash
chezmoi target-path dot_config/nushell
chezmoi target-path dot_bashrc
```

反向查看目标文件对应的 source path：

```bash
chezmoi source-path ~/.config/nushell
chezmoi source-path ~/.bashrc
```

## 相关链接

- [chezmoi 官方文档](https://www.chezmoi.io/)
- [chezmoi 加密文档](https://www.chezmoi.io/user-guide/encryption/)
- [GPG 对称加密说明](https://www.gnupg.org/documentation/manuals/gnupg/Symmetric-Encryption.html)

## License

本仓库主要为个人配置使用。如需复用，请先检查其中是否包含与你环境相关的私有路径、主机名或敏感配置。
