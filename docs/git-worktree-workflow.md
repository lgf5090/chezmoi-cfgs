# Git Worktree 工作流完整指南

> 一份从概念、命令、场景到最佳实践的 git worktree 完全手册。
> 适用 Git 2.15+（推荐使用最新版本以获得更稳定的体验）。

---

## 目录

1. [为什么需要 Git Worktree](#1-为什么需要-git-worktree)
2. [核心概念](#2-核心概念)
3. [与 clone / stash / submodule 的对比](#3-与-clone--stash--submodule-的对比)
4. [核心命令速查](#4-核心命令速查)
5. [基础用法](#5-基础用法)
6. [实战场景](#6-实战场景)
7. [进阶技巧](#7-进阶技巧)
8. [底层原理：.git 目录的变化](#8-底层原理git-目录的变化)
9. [避坑指南与使用限制](#9-避坑指南与使用限制)
10. [清理与维护](#10-清理与维护)
11. [推荐目录结构](#11-推荐目录结构)
12. [与 stash 的取舍](#12-与-stash-的取舍)
13. [最佳实践 Checklist](#13-最佳实践-checklist)
14. [常见问题 FAQ](#14-常见问题-faq)

---

## 1. 为什么需要 Git Worktree

### 1.1 传统分支切换的痛点

每个开发者都遇到过这样的场景：

- 你正在 `feature/login` 分支写了 200 行还没提交的代码，处于"心流"状态。
- 线上 `main` 突然挂了，需要立刻修 Bug。
- 此时你的选项只有：

| 方案 | 问题 |
|------|------|
| `git stash` → 切 `main` → 修 → 切回 → `stash pop` | 容易冲突、状态丢失、stash 栈混乱 |
| `git commit` 一个临时 WIP 提交再切 | 提交历史被污染，后续还要 soft-reset |
| 再 `git clone` 一份到别的目录 | 磁盘占用翻倍、配置/依赖要重装、两份仓库不同步 |
| 直接 `git checkout main` | Git 拒绝切换（本地修改会被覆盖） |

### 1.2 Worktree 的解决思路

**git worktree 让你把同一个仓库的不同分支，同时 checkout 到不同的目录里。**

打个比方：

- 传统的 Git 就像"只有一个房间的房子"，你想看另一个分支就得让前一个先出去。
- worktree 是"一栋楼里有多个房间"，每个房间住着一个分支，随时推门进出，互不打扰。

所有工作目录**共享同一个 `.git` 仓库**（commit、对象、远程配置），但文件、暂存区、HEAD 指针各自独立。

---

## 2. 核心概念

### 2.1 主工作树（Main Worktree）

- 通过 `git clone` 或 `git init` 创建的**原始仓库目录**。
- 包含完整的 `.git` **目录**（不是文件）。
- 是所有链接工作树的"母体"。
- 删除主工作树等于删除整个仓库。

### 2.2 链接工作树（Linked Worktree）

- 通过 `git worktree add` 创建的**额外工作目录**。
- 不含独立 `.git` 目录，而是包含一个 `.git` **文件**，内容是指向主工作树 `.git` 目录的指针：

  ```
  gitdir: /path/to/main-repo/.git/worktrees/<name>
  ```

- 主工作树的 `.git/worktrees/<name>/` 下会保存该链接工作树的元数据（HEAD、索引、ORIG_HEAD 等）。

### 2.3 关键特性

- **共享对象库**：所有 commit、tree、blob 都只存一份。
- **独立工作区**：每个工作树有自己的工作目录、暂存区、HEAD。
- **分支独占**：同一个分支不能同时在两个工作树中检出（Git 主动阻止，防止索引冲突）。
- **秒级创建**：因为不需要复制对象数据，只创建工作文件。

---

## 3. 与 clone / stash / submodule 的对比

| 方式 | 是否共享 .git | 磁盘占用 | 切换成本 | 典型场景 |
|------|--------------|---------|---------|---------|
| `git checkout` 切分支 | 共享 | 1 份 | 高（要 stash） | 线性单一开发 |
| `git clone` 多份 | 完全独立 | N 份（大） | 需手动 push/pull 同步 | 多机器/完全隔离 |
| `git stash` | 共享 | 1 份 | 易冲突/丢失 | 临时保存改动 |
| **`git worktree`** | **共享** | **仅多出工作文件** | **极低（秒切目录）** | **多分支并行开发** |
| `git submodule` | 独立子仓库 | 额外子目录 | 复杂（要更新引用） | 引入第三方仓库 |

**核心优势**：worktree 既像 clone 一样能"同时拥有多个分支"，又像 checkout 一样"共享同一份仓库数据"，是性价比最高的并行开发方案。

---

## 4. 核心命令速查

```bash
# 1. 为已存在的分支创建工作树
git worktree add <路径> <已有分支名>

# 2. 创建工作树的同时新建分支（基于当前 HEAD）
git worktree add -b <新分支名> <路径>

# 3. 创建工作树并新建分支，基于指定 commit/分支
git worktree add -b <新分支名> <路径> <起点commit>

# 4. 列出所有工作树
git worktree list
git worktree list -v          # 详细信息（含 commit 信息）

# 5. 删除指定工作树
git worktree remove <路径>
git worktree remove --force <路径>   # 强制删除（有未提交改动时）

# 6. 清理已失效的工作树记录（目录被手动删除时）
git worktree prune
git worktree prune --dry-run        # 预览将清理什么

# 7. 锁定/解锁工作树（防止被自动清理）
git worktree lock <路径> --reason "running long build"
git worktree unlock <路径>

# 8. 移动工作树到新位置
git worktree move <旧路径> <新路径>
```

记住前 5 条，后续场景都是它们的组合应用。

---

## 5. 基础用法

### 5.1 前置准备：确认 Git 版本

```bash
git --version
# 建议 ≥ 2.15，过低版本建议升级：
# macOS:  brew update && brew install git
# Ubuntu: sudo apt update && sudo apt install git -y
```

### 5.2 创建第一个链接工作树

假设当前在 `~/projects/myapp`（处于 `main` 分支），需要为 `feature/login` 开发新功能：

```bash
# 在 main 仓库目录中执行
git worktree add ../myapp-feature-login feature/login
# 输出：
# Preparing worktree (checking out 'feature/login')
# HEAD is now at abc1234 commit message
```

执行后：

- 在 `../myapp-feature-login` 目录创建了一个完整的工作区。
- 该目录的 `.git` 是一个**文件**，指向主仓库的 `.git/worktrees/myapp-feature-login/`。
- 你可以在两个目录之间随时 `cd` 切换，无需 `git checkout`。

### 5.3 创建工作树并新建分支

```bash
# 基于 main 创建新分支 feature/payments 并检出
git worktree add -b feature/payments ../myapp-feature-payments

# 基于指定起点创建
git worktree add -b hotfix/login ../myapp-hotfix v1.2.0
```

### 5.4 查看所有工作树

```bash
$ git worktree list
/home/dev/projects/myapp                    abc1234 [main]
/home/dev/projects/myapp-feature-login      def5678 [feature/login]
/home/dev/projects/myapp-feature-payments   ghi9012 [feature/payments]
```

### 5.5 删除工作树

```bash
# 干净的工作树直接删除
git worktree remove ../myapp-feature-login

# 有未提交改动时强制删除
git worktree remove --force ../myapp-feature-login

# 如果目录被 rm -rf 手动删了，清理元数据
git worktree prune
```

---

## 6. 实战场景

### 场景 1：开发到一半，紧急修复线上 Bug（最经典）

你在 `feature/login` 写了 200 行没提交，线上 `main` 挂了。

```bash
# 1. 不动当前分支！直接开一个新目录拉 main
git worktree add ../hotfix-bug main

# 2. 进入新目录，安心修 Bug
cd ../hotfix-bug
# ... 修改代码 ...
git add . && git commit -m "fix: 线上紧急 Bug"
git push origin main

# 3. 修完删掉这个临时目录
cd ../myapp
git worktree remove ../hotfix-bug
```

**关键点**：原来的 `feature/login` 那 200 行代码**一个字都没动**，完全不需要 stash。两个目录同时开着，用完即删。

### 场景 2：同时对比/测试两个分支

对比 `v1.0` 和 `v2.0` 的接口性能，或同时跑新旧两个版本的前端：

```bash
git worktree add ../app-v1 v1.0
git worktree add ../app-v2 v2.0

# 两个目录同时存在，分别起服务对比
cd ../app-v1 && npm run dev   # 端口 3000
cd ../app-v2 && npm run dev   # 端口 3001
```

适合做**回归测试、A/B 对比、版本兼容性验证**。

### 场景 3：长时间并行开发多个功能

同时推进 `feature/auth`、`feature/payment`、`feature/dashboard` 三个功能：

```bash
git worktree add ../auth      feature/auth
git worktree add ../payment   feature/payment
git worktree add ../dashboard feature/dashboard
```

每个目录用独立的 IDE 窗口打开，**上下文不切换、思路不中断**。

### 场景 4：跑长时间任务（编译/测试）时不阻塞主线

在一个分支跑 `npm run build`（10 分钟），又想在 `main` 继续写代码：

```bash
git worktree add ../build-task feature/heavy-build
cd ../build-task && npm run build &    # 后台编译
cd ../myapp                            # 回主线继续干活，互不影响
```

### 场景 5：PR / Code Review 本地化

不污染当前工作区，本地检出 PR 分支跑测试：

```bash
# 拉取 PR #42 到本地分支
git fetch origin pull/42/head:pr-42

# 为该 PR 创建工作树
git worktree add ../myapp-pr-42 pr-42

cd ../myapp-pr-42
npm test                       # 本地跑测试、IDE 跳转

# 审查完毕清理
cd ../myapp
git worktree remove ../myapp-pr-42
git branch -D pr-42
```

可以同时审查多个 PR，每个都在自己的目录里。

### 场景 6：双 AI 竞技（让两个 AI 各自实现同一功能）

```bash
git worktree add -b ai-a-task ../ai-a
git worktree add -b ai-b-task ../ai-b

# 两个 AI 在各自目录独立写代码，互不干扰
# 完成后对比差异
git diff ai-a-task..ai-b-task

# 选择更好的合并
cd ../myapp
git checkout dev
git merge ai-a-task
```

### 场景 7：长期运行分支监控 / 演示环境

```bash
git worktree add ../test-env test-branch
cd ../test-env && ./start_test_server.sh
# 这个目录可以长期保留，不影响主开发
```

### 场景 8：文档与代码同步更新（gh-pages 等）

```bash
git worktree add ../gh-pages gh-pages
# 主分支更新代码，gh-pages 分支同步更新文档站点
```

---

## 7. 进阶技巧

### 7.1 锁定工作树（防止误删）

对长期运行的工作树加锁，避免被脚本或 `prune` 清理：

```bash
git worktree lock ../build-task --reason "running long build, do not remove"
# 完成后解锁
git worktree unlock ../build-task
```

### 7.2 移动工作树

```bash
git worktree move ../old-location ../new-location
```

### 7.3 基于远程分支直接创建

```bash
git fetch origin
git worktree add -b feature/local ../wt-feature origin/feature/remote
# 本地新建 feature/local，起点是 origin/feature/remote
```

### 7.4 在 CI/CD 中并行构建

```bash
# 在 CI 脚本中为每个任务创建独立环境
for task in build test lint; do
  git worktree add ../$task ci-$task
  (cd ../$task && ./run_$task.sh) &
done
wait
```

### 7.5 配合 IDE / Editor

- **VS Code / Cursor**：每个工作树用独立窗口打开（`code ../myapp-feature-login`），各自有独立的扩展状态、终端、调试配置。
- **JetBrains 系列**：每个工作树作为独立项目打开。
- **Neovim / Vim**：LSP、quickfix 互不干扰，适合多窗口对照编辑。

### 7.6 配合 npm / pnpm / yarn

每个工作树是独立目录，依赖互不影响：

```bash
cd ../myapp-feature-login
pnpm install          # 独立 node_modules
pnpm dev
```

> **提示**：如果磁盘紧张，可用 pnpm 的全局 store 或 npm 的链接方案减少重复。

### 7.7 配合 Docker / Compose

不同分支启动不同容器栈，互不冲突：

```bash
cd ../myapp-feature-v2
docker compose -p appv2 up -d
```

用 `-p` 指定项目名避免容器名冲突。

---

## 8. 底层原理：.git 目录的变化

### 8.1 主工作树

主工作树有完整的 `.git` **目录**：

```
myapp/
├── .git/                  ← 完整目录
│   ├── HEAD
│   ├── objects/           ← 对象库（共享）
│   ├── refs/
│   ├── worktrees/         ← 链接工作树元数据
│   │   ├── myapp-feature-login/
│   │   │   ├── HEAD
│   │   │   ├── index
│   │   │   ├── ORIG_HEAD
│   │   │   └── commondir  ← 指回主 .git
│   │   └── ...
│   └── ...
└── src/
```

### 8.2 链接工作树

链接工作树的 `.git` 是一个**文件**：

```
myapp-feature-login/
├── .git                   ← 文件！内容是：
│                            gitdir: /home/dev/projects/myapp/.git/worktrees/myapp-feature-login
└── src/
```

### 8.3 为什么能秒级创建

- `git worktree add` **不复制对象数据**（blob/tree/commit 都在主仓库）。
- 只做：
  1. 创建工作目录文件（checkout 的文件）。
  2. 在主仓库 `.git/worktrees/<name>/` 写入少量元数据。
- 因此对大型仓库（几十 GB）也只是几秒钟。

### 8.4 为什么共享却独立

- `commondir` 让链接工作树知道共享对象库在哪 → 共享 commit、远程配置。
- 独立的 `HEAD` 和 `index` → 独立的分支指针和暂存区。

---

## 9. 避坑指南与使用限制

### 9.1 同一分支不能在多个工作树中检出

```bash
$ git worktree add ../new-feature feature/login
fatal: 'feature/login' is already checked out at '/home/dev/projects/myapp-feature-login'
```

**解决**：换一个新分支，或先 remove 旧工作树。

### 9.2 工作树必须放在主仓库目录之外

不能把工作树创建在主仓库**内部**（会导致嵌套污染、被 Git 跟踪）：

```bash
# 错误：嵌套
git worktree add ./sub-wt feature/x   # 不推荐

# 正确：作为兄弟目录
git worktree add ../myapp-wt feature/x
```

### 9.3 删除工作树前先确认无未提交改动

```bash
git worktree remove ../myapp-feature-login
# fatal: 'myapp-feature-login' contains modified or untracked files
```

确认后用 `--force`，或先 `git stash` / `git commit`。

### 9.4 不要手动 `rm -rf` 工作树目录

手动删除会让 `.git/worktrees/<name>/` 元数据残留，导致 `git worktree list` 显示已不存在的项。

**正确做法**：用 `git worktree remove`，它会同时清理元数据。
**补救做法**：已经手动删了，就执行 `git worktree prune`。

### 9.5 子模块（submodule）需在主仓库统一管理

```bash
# 在每个新工作树中重新初始化子模块
cd ../myapp-feature-login
git submodule update --init --recursive
```

### 9.6 `git pull` 在工作树中的行为

工作树可以正常 `pull/push/commit`，与普通仓库无差异。但要注意：

- 如果主工作树和其他工作树共享同一远程跟踪分支，`fetch` 是共享的。
- 各自的本地分支独立，互不影响。

### 9.7 GUI 客户端支持差异

部分 Git GUI 客户端对 worktree 支持不完整。命令行始终是最可靠的。

---

## 10. 清理与维护

### 10.1 日常清理

```bash
# 删除单个工作树（推荐）
git worktree remove ../myapp-feature-auth

# 清理所有失效记录
git worktree prune

# 预览将清理什么
git worktree prune --dry-run

# 删除已合并的本地分支
git branch -d feature/auth
```

### 10.2 批量清理脚本

```bash
# 删除所有已合并分支对应的工作树（谨慎使用）
git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | \
  while read wt; do
    [ "$wt" = "$(git rev-parse --show-toplevel)" ] && continue
    echo "Removing: $wt"
    git worktree remove "$wt" --force
  done

# 清理失效记录
git worktree prune -v
```

### 10.3 自动化：post-merge 钩子

在 `.git/hooks/post-merge` 中加入：

```bash
#!/bin/sh
git worktree prune
```

合并后自动清理失效工作树记录。

### 10.4 定期巡检

```bash
# 查看所有工作树状态
git worktree list -v

# 检查是否有未提交改动
for wt in $(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2); do
  echo "=== $wt ==="
  git -C "$wt" status -s
done
```

---

## 11. 推荐目录结构

### 11.1 平铺式（推荐）

所有工作树作为主仓库的兄弟目录：

```
~/projects/
├── myapp/                    # main 分支（稳定参考）
├── myapp-feature-auth/       # 认证功能
├── myapp-feature-payments/   # 支付集成
├── myapp-experiment-new-ui/  # UI 实验
└── myapp-bugfix-cart/        # 购物车修复
```

**优点**：路径短、清晰、不嵌套、易管理。

### 11.2 专用父目录式

将所有工作树收纳到一个父目录：

```
~/projects/myapp-wt/
├── main/                     # 主工作树
├── feature-auth/
├── feature-payments/
└── hotfix-123/
```

**优点**：项目集中、备份方便。

### 11.3 命名规范建议

| 分支类型 | 工作树命名 | 示例 |
|---------|-----------|------|
| 主分支 | 项目名 / `main` | `myapp` |
| 功能 | `项目名-feature-名` | `myapp-feature-auth` |
| 修复 | `项目名-hotfix-编号` | `myapp-hotfix-123` |
| 实验 | `项目名-exp-描述` | `myapp-exp-new-ui` |
| PR 审查 | `项目名-pr-编号` | `myapp-pr-42` |
| 发布 | `项目名-release-版本` | `myapp-release-2.0` |

---

## 12. 与 stash 的取舍

### 12.1 何时该用 worktree

- ✅ 需要超过 30 分钟的上下文切换。
- ✅ 同时进行多个关联性低的任务。
- ✅ 长期运行分支（演示环境、测试环境）。
- ✅ 避免污染主开发分支。
- ✅ 需要并排对比多个分支的代码。
- ✅ 跑长时间构建/测试时不想阻塞主线。

### 12.2 何时该用 stash

- ⏱️ 5 分钟内的快速切换（如拉取远程更新）。
- 📦 临时保存未纳入版本控制的文件改动。
- 🧹 单一仓库内的小范围上下文切换，不值得为它开一个目录。
- 🔁 频繁在同两个分支之间来回切。

### 12.3 性能对比（10 万行代码仓库）

| 操作 | git stash | git worktree |
|------|-----------|--------------|
| 保存上下文 | ~2.8s | ~0.3s |
| 恢复工作 | ~4.1s | ~0.1s（直接 cd） |
| 空间占用 | 增量存储 | 硬链接节省 ~70% |
| 冲突风险 | 高 | 无（独立工作区） |

> **结论**：worktree 不是要完全取代 stash，而是把 **30% 的 stash 场景升级为更优雅的方案**。

---

## 13. 最佳实践 Checklist

### 创建

- [ ] 始终把工作树放在**主仓库的兄弟目录**，不要嵌套。
- [ ] 用 `-b` 显式为新工作树创建新分支，避免误用主分支。
- [ ] 命名遵循统一规范（`项目名-类型-描述`）。
- [ ] 为长期运行的工作树加 `lock` 并写明 reason。

### 使用

- [ ] 每个工作树用独立的 IDE 窗口打开。
- [ ] 依赖目录（`node_modules`、`target`、`build`）在各工作树独立维护。
- [ ] 跨工作树对比用 `git diff <branch-a>..<branch-b>`，不要手动复制文件。
- [ ] 提交前确认当前所在工作树（`pwd` 或 `git rev-parse --show-toplevel`）。

### 清理

- [ ] 分支合并后立即 `git worktree remove` 对应工作树。
- [ ] 用 `git worktree remove`，**不要**手动 `rm -rf`。
- [ ] 误删后用 `git worktree prune` 补救。
- [ ] 定期执行 `git worktree prune` 或加到 `post-merge` 钩子。
- [ ] 删除工作树后再删除对应本地分支：`git branch -d <branch>`。

### 协作

- [ ] 团队统一目录结构约定（推荐平铺式）。
- [ ] README 中记录团队的 worktree 命名规范。
- [ ] CI 脚本中清理工作树时加 `--force` 兜底。
- [ ] 对新成员做一次 worktree 工作流培训。

---

## 14. 常见问题 FAQ

### Q1：worktree 会复制整个仓库吗？

**不会**。所有工作树共享同一个 `.git` 对象库，`git worktree add` 只创建工作文件和少量元数据，因此秒级完成。

### Q2：在一个工作树里 commit，其他工作树能立即看到吗？

能看到新的 commit（共享对象库），但其他工作树的**工作目录文件不会自动更新**——它们仍然停留在自己检出的分支。要看到新代码，需在该工作树中 `git fetch` 或 `git merge`/`git rebase`。

### Q3：可以把工作树创建在主仓库内部吗？

**不推荐**。会导致嵌套污染，Git 可能会跟踪到它。始终创建在**兄弟目录**。

### Q4：删除工作树会删掉分支吗？

**不会**。`git worktree remove` 只删除工作目录和元数据，分支仍然保留。需要手动 `git branch -d <branch>` 删除分支。

### Q5：工作树支持 Windows 吗？

**支持**。Git 2.15+ 在 Windows 上稳定可用。注意路径用正斜杠 `/` 或反斜杠 `\` 均可，但脚本中建议用正斜杠保持跨平台兼容。

### Q6：可以在 U 盘 / 网络盘上创建工作树吗？

**可以但不推荐**。网络盘可能导致文件锁问题，影响 Git 性能。建议在本地磁盘创建。

### Q7：`git worktree list` 显示的工作树路径是绝对路径，能改相对路径吗？

不能。Git 内部存储绝对路径。移动主仓库后需 `git worktree repair` 修复路径。

### Q8：工作树被误删怎么恢复？

```bash
# 1. 清理失效元数据
git worktree prune

# 2. 重新创建
git worktree add ../myapp-feature-login feature/login
# 分支和 commit 都还在，工作文件会重新 checkout
```

### Q9：如何在两个工作树之间快速 cd？

可以在 shell 配置中加一个函数：

```bash
# ~/.zshrc 或 ~/.bashrc
wt() {
  local target=$(git worktree list | fzf | awk '{print $1}')
  [ -n "$target" ] && cd "$target"
}
```

按 `wt` 即可模糊选择并跳转。

### Q10：worktree 和 submodule 能一起用吗？

**可以**。在链接工作树中执行 `git submodule update --init --recursive` 即可初始化子模块。注意子模块配置在主仓库统一管理。

---

## 附录：快速上手 5 步

```bash
# 1. 在主仓库创建一个功能分支的工作树
git worktree add -b feature/x ../myapp-feature-x

# 2. 进入工作树开发
cd ../myapp-feature-x
# ... 写代码、提交 ...
git add . && git commit -m "feat: 实现 X"
git push -u origin feature/x

# 3. 在主仓库合并
cd ../myapp
git merge feature/x

# 4. 删除工作树
git worktree remove ../myapp-feature-x

# 5. 删除已合并分支
git branch -d feature/x
```

---

## 参考资料

- [Git Worktree 官方文档](https://git-scm.com/docs/git-worktree)
- [Git Worktree Workflow for Parallel Development](https://www.gitworktree.org/guides/workflow)
- [一文搞懂 Git Worktree：多分支并行开发的神器](https://blog.csdn.net/weixin_45284808/article/details/162179002)
- [Git worktree 终极指南](https://juejin.cn/post/7627720938671095835)
- [让 30% 的 git stash 惨遭失业：解锁并行开发新姿势](https://blog.csdn.net/Mingcai_Xiong/article/details/149164371)
- [Git Worktree 与 Cursor WorkTree 完全指南](https://juejin.cn/post/7612949440031424512)
