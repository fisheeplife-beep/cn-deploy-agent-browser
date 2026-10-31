# agent-browser 国内可跟做部署配套

> **系列索引：** [cn-deploy](https://github.com/fisheeplife-beep/cn-deploy) — 中文可跟做部署配套合集。

> 上游仓库：[vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser)  
> 官方文档 / 站点：https://agent-browser.dev  
> npm：[`agent-browser`](https://www.npmjs.com/package/agent-browser)  
> 本仓性质：**独立中文部署配套**（脚本 / 国内网络兜底 / 踩坑记录），**不是**官方镜像，也**不会**整页搬运上游 README。

agent-browser 是给 AI Agent 用的**浏览器自动化 CLI**（原生 Rust 客户端 + daemon，经 CDP 控 Chrome）。典型工作流：`open` → `snapshot`（带 `@eN` ref）→ `click` / `fill` → `screenshot`。  
本仓目标：在**国内网络 / 常见 Linux 或 macOS** 上，把 CLI 和 Chrome 装到能跑通冒烟，并知道成功长什么样。

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-10-31，Asia/Shanghai） |
|------|--------------------------------------------------|
| **npm 全局安装 `agent-browser@0.41.0`**（Node **24.11.0**） | ✅ **已验证** — `agent-browser 0.41.0` |
| **`agent-browser install`** 拉 Chrome for Testing | ✅ **已验证** — `156.0.8078.80` → `~/.agent-browser/browsers/chrome-156.0.8078.80/` |
| **`agent-browser doctor`**（含无头启动实测） | ✅ **已验证** — Summary **10 pass, 0 warn, 0 fail** |
| **冒烟：`open https://example.com` → title / snapshot / screenshot / close** | ✅ **已验证** — 见 [`examples/`](./examples/) |
| **`agent-browser read https://example.com`**（不启 Chrome） | ✅ **已验证** — 拉到可读正文 |
| **`./scripts/install-chrome.sh mirror`**（npmmirror zip） | ⚠️ **脚本已写好**；本机官方 install 已成功，**未再完整重下**验证镜像路径（zip URL 已用 HTTP 200 探活） |
| **`agent-browser install --with-deps`** | ⚠️ **未完整验证**（需 sudo；本机已有可用 Chrome 库） |
| **Homebrew / Cargo 安装** | ⚠️ **未在本机验证**（无 brew；有 cargo 但未跑 `cargo install`） |
| **AI `chat` / Browserbase 等云浏览器** | ⚠️ **未验证** — 需 `AI_GATEWAY_API_KEY` 等密钥 |

示例输出：[`examples/doctor-offline.txt`](./examples/doctor-offline.txt)、[`examples/smoke-example.com.txt`](./examples/smoke-example.com.txt)、[`examples/example.png`](./examples/example.png)。

---

## 它到底怎么装？（真实安装面）

上游推荐路径（按常见程度）：

| 方式 | 命令 | 说明 |
|------|------|------|
| **npm 全局（推荐）** | `npm install -g agent-browser` 然后 `agent-browser install` | 装的是**原生二进制**分发，不是「要长期挂着 Node 服务」；`package.json` engines 写 **Node ≥ 24** |
| npm 项目依赖 | `npm install agent-browser` + `agent-browser install` | 版本钉在 `package.json` |
| Homebrew（macOS） | `brew install agent-browser` + `agent-browser install` | 本仓未实测 |
| Cargo | `cargo install agent-browser` + `agent-browser install` | 本仓未实测 |
| 源码 | Node 24+、pnpm 11+、Rust；`pnpm build` / `pnpm build:native` | 重，国内慎选 |

**第二步几乎总要做：** `agent-browser install` —— 从 [Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing/) 下载专用 Chrome。  
若本机已有 Chrome / Brave / Playwright / Puppeteer 浏览器，daemon 也可能自动发现；国内若 Google CDN 不通，见下文「国内网络」或直接指定：

```bash
export AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/google-chrome
```

Linux 若缺系统库：`agent-browser install --with-deps`（非 root 会走 sudo）。

---

## 环境要求（最小可跑）

- **装 CLI（npm 路径）**：Node.js **≥ 24**（本仓实测 24.11.0）
- **跑浏览器**：Chrome for Testing（`agent-browser install`）**或**本机 Chrome/Chromium + `AGENT_BROWSER_EXECUTABLE_PATH`
- **磁盘**：建议预留 ≥ 1–2 GB（zip ~190MB + 解压）
- **可选**：`ffmpeg`（`record` 录视频才需要）
- **可选**：HTTP 代理（`AGENT_BROWSER_PROXY`）—— Google CDN / 部分站点访问

可选先体检：

```bash
./scripts/preflight.sh
# 或你已有的 cn-deploy-doctor
```

---

## 五分钟落地（已验证路径）

### 1. Node 24+

```bash
node -v    # 需要 v24.x
npm -v
```

不够就去 [Node 发行页](https://nodejs.org/dist/) 或 [npmmirror Node 镜像](https://npmmirror.com/mirrors/node/) 装 24，再开新终端。

### 2. 装 CLI

```bash
./scripts/install-cli.sh
# 等价于：
# npm install -g agent-browser
agent-browser --version
```

国内 npm 慢时可：

```bash
npm config set registry https://registry.npmmirror.com
# 若包解析异常，临时：
# npm install -g agent-browser --registry https://registry.npmjs.org
```

### 3. 装 / 指定 Chrome

```bash
# 优先官方（与 upstream 一致）
./scripts/install-chrome.sh
# 或显式：
# ./scripts/install-chrome.sh official
# Google CDN 失败且是 Linux x64：
# ./scripts/install-chrome.sh mirror
# 只用系统浏览器：
# ./scripts/install-chrome.sh system
```

官方成功时类似：

```text
✓ Chrome 156.0.8078.80 installed successfully
  Location: ~/.agent-browser/browsers/chrome-156.0.8078.80
```

### 4. doctor

```bash
agent-browser doctor
# 无网快速看本地：
agent-browser doctor --offline --quick
```

成功标准（本仓实测）：出现 **Launch test → pass Headless launch**，Summary 里 **fail = 0**。

### 5. 冒烟

```bash
./scripts/smoke.sh
# 或手工：
agent-browser open https://example.com
agent-browser get title          # Example Domain
agent-browser snapshot -i
agent-browser screenshot /tmp/ab.png
agent-browser close
```

---

## 国内网络与镜像

详见 [`docs/china-network.md`](./docs/china-network.md)。摘要：

1. **CLI 包**：npmmirror / npmjs 一般都能下到 `agent-browser`。  
2. **Chrome for Testing**：默认走 `storage.googleapis.com`，国内常超时；可  
   - 系统 Chrome + `AGENT_BROWSER_EXECUTABLE_PATH`  
   - `AGENT_BROWSER_PROXY=http://127.0.0.1:端口` 后再 `agent-browser install`  
   - Linux x64：`./scripts/install-chrome.sh mirror`（npmmirror zip）  
3. agent-browser **没有** Playwright 那套 `PLAYWRIGHT_DOWNLOAD_HOST`；别照搬 Playwright 镜像环境变量指望生效。

`.env.example` 里列了常用 `AGENT_BROWSER_*` 变量，可按需 `export`。

---

## 给 AI / 脚本的最小用法

```bash
agent-browser open https://example.com
agent-browser snapshot -i --json    # 解析 refs
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser screenshot --if-changed page.png
agent-browser close
```

多步可 `batch`，或依赖后台 daemon 连续调用（idle 默认约 1h 无操作会退出）。

MCP：

```bash
agent-browser mcp
# 客户端配置 command=agent-browser args=["mcp"]
```

安全相关（Agent 部署建议打开）：`--allowed-domains`、`--content-boundaries`、`--max-output` 等，见上游 Security 文档。

---

## 常见报错

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| `engines` / Node 版本报错 | Node &lt; 24 | 升级到 24+ |
| `npm ERR!` / 超时 | npm 源不通 | 换 npmmirror，或 `--registry https://registry.npmjs.org` |
| `agent-browser install` 下载卡住/失败 | Google CDN | 代理，或 `install-chrome.sh mirror`，或系统 Chrome |
| `shared library` / 浏览器起不来（Linux） | 缺系统依赖 | `agent-browser install --with-deps` |
| doctor Launch test fail | 无显示/无 Chrome/权限 | 先 `doctor --json`；无头环境一般可直接跑；确认 `~/.agent-browser/browsers` 或 `EXECUTABLE_PATH` |
| `EAGAIN` / 命令超时 | 页面太慢 | 增大 `AGENT_BROWSER_DEFAULT_TIMEOUT`（注意勿盲目 &gt;30000） |
| macOS &lt; 13 拒绝装 CFT | 上游策略 | 升级系统或手动装 Chrome，再设 `EXECUTABLE_PATH` |
| `record` 失败 | 无 ffmpeg | 装 ffmpeg；不录视频可忽略 |
| `chat` 不可用 | 无 AI Gateway Key | 设 `AI_GATEWAY_API_KEY`（可选功能） |

排障顺序建议：`doctor` → 看 Chrome 路径 → `open about:blank` → 再 `open` 目标站。

---

## 本仓脚本一览

| 脚本 | 作用 |
|------|------|
| `scripts/preflight.sh` | Node / npm / 浏览器 / 磁盘 / 关键 URL 预检 |
| `scripts/install-cli.sh` | `npm install -g agent-browser` |
| `scripts/install-chrome.sh` | `auto\|official\|mirror\|system` |
| `scripts/smoke.sh` | example.com 端到端冒烟 |
| `scripts/verify.sh` | version + doctor + smoke |

---

## 升级

```bash
agent-browser upgrade
# 或：npm install -g agent-browser@latest
```

---

## 与上游的关系

- 功能以 [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) 与 https://agent-browser.dev 为准。  
- 本仓只提供**中文可跟做步骤、国内网络兜底脚本、验证记录**。  
- 配套仓库许可证：MIT（见 `LICENSE`）。上游与 Chrome 二进制各有其许可证。

相关开源：[`cn-deploy-doctor`](https://github.com/fisheeplife-beep/cn-deploy-doctor)（环境体检）、[`trending-gap-radar`](https://github.com/fisheeplife-beep/trending-gap-radar)（选题）。

---

## 成功标准（你自己验收）

1. `agent-browser --version` 有输出  
2. `agent-browser doctor` 无 fail，Launch test pass（或你已用系统 Chrome 且能 `open`）  
3. `./scripts/smoke.sh` 退出码 0，截图文件非空  

都满足，就可以接你的 Agent / MCP / 脚本了。
