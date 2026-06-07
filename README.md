
# 🚀 My Chezmoi Dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理的个人配置文件（dotfiles），支持跨多台机器安全同步，并通过 **GPG 对称加密** 保护敏感文件（如 `~/.ssh/`）。

## 📦 前置依赖

在新机器上部署前，请确保已安装以下工具：

- [chezmoi](https://www.chezmoi.io/install/) – 核心管理工具
- [git](https://git-scm.com/) – 版本控制
- [GnuPG (gpg)](https://gnupg.org/) – 用于对称加密解密

[chezmoi安装教程](https://www.chezmoi.io/install/#__tabbed_2_1)

```bash
sudo apt update && sudo apt install -y bash zsh fish git gnupg
```

docker
```bash
docker run -it ubuntu bash
```

```bash
apt update && apt install -y bash zsh fish git gnupg
```

安装chezmoi
```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)"
```

## 🛠️ 首次安装与使用

### 1️⃣ 克隆并应用配置

```bash
chezmoi init --apply https://github.com/lgf5090/chezmoi-cfgs.git
```

执行后，chezmoi 会：
- 克隆本仓库到 `~/.local/share/chezmoi`
- 自动执行模板，生成本地配置文件 `~/.config/chezmoi/chezmoi.toml`
- 将所有 dotfiles 链接到正确的位置（如 `~/.bashrc`、`~/.gitconfig` 等）

### 2️⃣ 输入 GPG 密码

由于采用了 **GPG 对称加密**（配置文件 `chezmoi.toml` 中已定义），在首次 `chezmoi apply` 或后续更新时，若遇到加密文件，系统会提示你输入解密密码。

> 💡 该密码是你之前加密敏感文件时设置的 **GPG 对称加密密码**，请妥善保管。

### 3️⃣ 检查效果

```bash
ls -la ~/.ssh        # 应该看到解密后的文件
chezmoi verify       # 检查是否有未应用的变更
```

## 🔐 添加或更新敏感文件（如 ~/.ssh）

如果你想添加新的私钥或更新 `~/.ssh/config`，请按照以下步骤操作：

1. **将文件加入 chezmoi 并加密**

   ```bash
   chezmoi add --encrypt ~/.ssh/id_rsa
   # 或递归添加整个目录
   chezmoi add --encrypt --recursive ~/.ssh
   ```

   GPG 会弹出提示输入密码（用于加密），请牢记该密码。

2. **查看加密后的文件**

   ```bash
   ls ~/.local/share/chezmoi/dot_ssh/
   # 输出类似：encrypted_id_rsa  encrypted_config
   ```

3. **提交并推送变更**

   ```bash
   cd ~/.local/share/chezmoi
   git add dot_ssh/
   git commit -m "Update SSH config"
   git push
   ```

## 📂 添加普通（非敏感）配置文件

对于不需要加密的配置文件（如 `~/.gitconfig`），直接添加即可：

```bash
chezmoi add ~/.gitconfig
chezmoi apply
git -C ~/.local/share/chezmoi add .
git -C ~/.local/share/chezmoi commit -m "Add gitconfig"
git -C ~/.local/share/chezmoi push
```

## 🔄 日常更新工作流

- **编辑源文件后应用变更**：  
  ```bash
  chezmoi edit ~/.bashrc     # 修改源文件
  chezmoi apply              # 部署到真实 HOME
  ```

- **查看哪些文件会被修改**：  
  ```bash
  chezmoi diff
  ```

- **将外部修改同步回仓库**：  
  如果你直接修改了 `~/.bashrc`，需要反向同步到 chezmoi：
  ```bash
  chezmoi re-add ~/.bashrc
  ```

- **拉取上游更新并应用**：  
  ```bash
  chezmoi update -v
  ```

## ❓ 常见问题

### Q：每次 `chezmoi apply` 都要求输入 GPG 密码，很烦怎么办？

A：GPG 对称加密会每次都询问密码。如果你希望“一次输入，会话内记住”，可以参考官方文档使用 `promptStringOnce` 模板（[链接](https://www.chezmoi.io/user-guide/encryption/gpg/#symmetric-encryption-with-a-passphrase)）。或者改用 `age` 配合 `passphrase = true` 并安装 `age` 工具。

### Q：为什么不能直接 `chezmoi add ~/.config/chezmoi/chezmoi.toml`？

A：chezmoi 禁止将自己的配置文件直接加入仓库，这会破坏跨机器的差异化设计。正确做法是使用模板 `.chezmoi.toml.tmpl`（本仓库已提供）。

### Q：换了一台新机器，初始化后 SSH 私钥权限不对？

A：可以在模板或脚本中添加 `run_once_` 脚本修正权限，例如：

```bash
#!/bin/bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
```

### Q：我忘记 GPG 加密密码了怎么办？

A：很遗憾，对称加密的密码无法找回。你需要删除加密文件（如 `encrypted_id_rsa`），重新运行 `chezmoi add --encrypt` 并设置一个新的密码。

## 📚 相关链接

- [chezmoi 官方文档](https://www.chezmoi.io/)
- [GPG 对称加密指南](https://www.gnupg.org/documentation/manuals/gnupg/Symmetric-Encryption.html)

## 📄 许可证

本仓库中的配置文件遵循 [MIT License](LICENSE)（如果存在）或仅为个人使用，请自行判断。
```
