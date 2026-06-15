# AI CLI 安装清单

本文记录通过 npm 全局安装的 AI / Coding Agent CLI。当前全局 npm 前缀为：

```powershell
npm config get prefix
# C:\Users\lgf50\.npm-global
```

## 1. 一键安装

安装当前清单中的全部 AI CLI 包：

```powershell
npm install -g --ignore-scripts `
  @anthropic-ai/claude-code `
  @augmentcode/auggie `
  @deveco/deveco-code `
  @earendil-works/pi-coding-agent `
  @github/copilot `
  @google/gemini-cli `
  @mimo-ai/cli `
  @moonshot-ai/kimi-code `
  @musistudio/claude-code-router `
  @oh-my-pi/pi-coding-agent `
  @openai/codex `
  @qwen-code/qwen-code `
  @tencent-ai/codebuddy-code `
  groq-code-cli `
  opencode-ai
```

如需精确复现当前机器上的版本：

```powershell
npm install -g --ignore-scripts `
  @anthropic-ai/claude-code@2.1.177 `
  @augmentcode/auggie@0.29.0 `
  @deveco/deveco-code@0.1.0 `
  @earendil-works/pi-coding-agent@0.79.4 `
  @github/copilot@1.0.62 `
  @google/gemini-cli@0.46.0 `
  @mimo-ai/cli@0.1.1 `
  @moonshot-ai/kimi-code@0.14.3 `
  @musistudio/claude-code-router@2.0.0 `
  @oh-my-pi/pi-coding-agent@15.13.3 `
  @openai/codex@0.139.0 `
  @qwen-code/qwen-code@0.18.0 `
  @tencent-ai/codebuddy-code@2.106.3 `
  groq-code-cli@1.0.2 `
  opencode-ai@1.17.7
```

> `--ignore-scripts` 适合安全优先的全局安装。若某个 CLI 首次运行提示缺少二进制、权限或 postinstall 产物，确认包来源后再单独重装该包并移除 `--ignore-scripts`。

## 2. 已安装包

| 包名 | 命令 | 当前版本 | npm 最新 | 简介 | 官网 / 文档 | GitHub / 仓库 |
| --- | --- | --- | --- | --- | --- | --- |
| `@anthropic-ai/claude-code` | `claude` | `2.1.177` | `2.1.177` | Anthropic Claude Code，本地终端代码代理。 | <https://github.com/anthropics/claude-code> | npm 元数据指向内部仓库；公开入口见官网 / 文档 |
| `@augmentcode/auggie` | `auggie` | `0.29.0` | `0.29.0` | Augment Code 的命令行客户端。 | <https://augmentcode.com> | npm 元数据未声明 |
| `@deveco/deveco-code` | `deveco` | `0.1.0` | `0.1.0` | 面向 HarmonyOS 开发场景的 AI Agent。 | <https://www.npmjs.com/package/@deveco/deveco-code> | npm 元数据未声明 |
| `@earendil-works/pi-coding-agent` | `pi` | `0.79.4` | `0.79.4` | Pi coding agent，提供读写文件、命令执行和会话管理。 | <https://github.com/earendil-works/pi#readme> | <https://github.com/earendil-works/pi> |
| `@github/copilot` | `copilot` | `1.0.62` | `1.0.62` | GitHub Copilot CLI，将 Copilot coding agent 带到终端。 | <https://github.com/github/copilot-cli/#readme> | <https://github.com/github/copilot-cli> |
| `@google/gemini-cli` | `gemini` | `0.46.0` | `0.46.0` | Google Gemini CLI。 | <https://github.com/google-gemini/gemini-cli#readme> | <https://github.com/google-gemini/gemini-cli> |
| `@mimo-ai/cli` | `mimo` | `0.1.1` | `0.1.1` | Xiaomi MiMo Code CLI。 | <https://mimo.xiaomi.com/en/mimocode> | <https://github.com/XiaomiMiMo/MiMo-Code> |
| `@moonshot-ai/kimi-code` | `kimi` | `0.14.3` | `0.15.0` | Moonshot AI Kimi Code，代码代理 CLI。 | <https://github.com/MoonshotAI/kimi-code/tree/main/apps/kimi-code#readme> | <https://github.com/MoonshotAI/kimi-code> |
| `@musistudio/claude-code-router` | `ccr` | `2.0.0` | `2.0.0` | Claude Code Router，将 Claude Code 请求路由到其他 LLM Provider。 | <https://www.npmjs.com/package/@musistudio/claude-code-router> | <https://github.com/musistudio/claude-code-router> |
| `@oh-my-pi/pi-coding-agent` | `omp` | `15.13.3` | `16.0.0` | Oh My Pi coding agent。 | <https://omp.sh> | <https://github.com/can1357/oh-my-pi> |
| `@openai/codex` | `codex` | `0.139.0` | `0.139.0` | OpenAI Codex CLI，本地运行的 coding agent。 | <https://github.com/openai/codex#readme> | <https://github.com/openai/codex> |
| `@qwen-code/qwen-code` | `qwen` | `0.18.0` | `0.18.1` | Qwen Code，通义千问代码代理 CLI。 | <https://github.com/QwenLM/qwen-code#readme> | <https://github.com/QwenLM/qwen-code> |
| `@tencent-ai/codebuddy-code` | `codebuddy`, `cbc` | `2.106.3` | `2.106.4` | Tencent CodeBuddy Code，腾讯代码助手 CLI。 | <https://cnb.cool/codebuddy/codebuddy-code> | npm 元数据未声明 GitHub |
| `groq-code-cli` | `groq` | `1.0.2` | `1.0.2` | 第三方 Groq coding CLI。 | <https://www.npmjs.com/package/groq-code-cli> | npm 元数据未声明 |
| `opencode-ai` | `opencode` | `1.17.7` | `1.17.7` | OpenCode 终端 AI coding agent。 | <https://opencode.ai> | <https://github.com/sst/opencode> |

## 3. 单包安装

常用单包安装命令：

```powershell
npm install -g --ignore-scripts @anthropic-ai/claude-code
npm install -g --ignore-scripts @openai/codex
npm install -g --ignore-scripts @google/gemini-cli
npm install -g --ignore-scripts @qwen-code/qwen-code
npm install -g --ignore-scripts @moonshot-ai/kimi-code
npm install -g --ignore-scripts @github/copilot
npm install -g --ignore-scripts @augmentcode/auggie
npm install -g --ignore-scripts @tencent-ai/codebuddy-code
npm install -g --ignore-scripts @mimo-ai/cli
npm install -g --ignore-scripts opencode-ai
npm install -g --ignore-scripts @oh-my-pi/pi-coding-agent
npm install -g --ignore-scripts @musistudio/claude-code-router
```

你之前单独安装 `@oh-my-pi/pi-coding-agent` 的命令可以保留：

```powershell
npm install -g --ignore-scripts @oh-my-pi/pi-coding-agent
```

## 4. 安装后检查

查看全局包：

```powershell
npm list -g --depth=0
```

检查命令是否进入 PATH：

```powershell
Get-Command claude,codex,gemini,qwen,kimi,copilot,auggie,codebuddy,cbc,mimo,opencode,omp,ccr,groq,pi -ErrorAction SilentlyContinue
```

检查可更新版本：

```powershell
npm outdated -g --depth=0
```

更新指定包：

```powershell
npm update -g @openai/codex @google/gemini-cli @qwen-code/qwen-code
```

## 5. 可选补充

这些工具未出现在当前 `npm list -g` 中，但也常用于 AI 编程工作流：

| 工具 | 安装方式 | 官网 / 文档 | GitHub / 仓库 | 说明 |
| --- | --- | --- | --- | --- |
| Amp | `npm install -g --ignore-scripts @ampcode/cli` | <https://ampcode.com> | npm 元数据未声明；旧包 `@sourcegraph/amp` 指向 <https://github.com/sourcegraph/amp> | Sourcegraph / Amp 的 coding agent CLI；`@sourcegraph/amp` 已重命名为 `@ampcode/cli`。 |
| Aider | `pipx install aider-chat` | <https://aider.chat> | <https://github.com/Aider-AI/aider> | 成熟的终端 pair programming 工具，适合 Git 仓库内的代码修改。 |
| Goose | 按官方文档安装 | <https://block.github.io/goose> | <https://github.com/block/goose> | Block 开源的本地 AI agent，可作为非 npm 体系的补充。 |
| Cursor Agent | 按官方文档安装 | <https://cursor.com> | 官方未提供独立开源仓库 | Cursor 的终端 agent 能力，适合已使用 Cursor 账号的环境。 |

## 6. 备注

- npm 包页统一格式为 `https://www.npmjs.com/package/<包名>`，带 scope 的包名需要 URL 编码或直接在浏览器中打开。
- 本文中的“npm 最新”基于 `npm view` 在 2026-06-16 读取到的元数据。
- 如果使用 npm 镜像源，建议定期切回官方 registry 检查版本差异：

```powershell
npm config get registry
npm view @openai/codex version --registry=https://registry.npmjs.org
```
