# 国内网络说明（agent-browser）

## 你需要通的几条链路

| 用途 | 地址 | 国内常见情况 |
|------|------|----------------|
| 装 CLI（npm） | `registry.npmjs.org` / `registry.npmmirror.com` | npmmirror 通常可直连；官方源偶发慢 |
| 装 Chrome for Testing | `storage.googleapis.com/chrome-for-testing-public/...` | **经常被墙或极慢** |
| 查最新 Chrome 版本 JSON | `googlechromelabs.github.io/chrome-for-testing/...` | 多数时候可访问（体积小） |
| 镜像 zip（社区） | `cdn.npmmirror.com/binaries/chrome-for-testing/<ver>/linux64/chrome-linux64.zip` | 适合 Linux x64 手动/脚本兜底 |
| 文档站 | `https://agent-browser.dev` | 一般可访问 |

CLI 本身是 **原生 Rust 二进制**（npm 包只是分发壳），daemon **不依赖 Node**。装完后日常操作主要吃本机 Chrome；卡点几乎总在 **第一次 `agent-browser install` 拉浏览器**。

## 推荐策略（按优先级）

1. **已有 Chrome/Chromium**：跳过下载  
   ```bash
   export AGENT_BROWSER_EXECUTABLE_PATH=$(command -v google-chrome || command -v chromium)
   agent-browser doctor
   ```
2. **官方 `agent-browser install` 能通**：最好（与 upstream 一致）。
3. **Google CDN 失败**：  
   ```bash
   ./scripts/install-chrome.sh mirror   # Linux x64 → npmmirror zip
   ```
4. **有本地 HTTP 代理**：  
   ```bash
   export AGENT_BROWSER_PROXY=http://127.0.0.1:7890
   agent-browser install
   ```
5. **Linux 缺共享库**：`agent-browser install --with-deps`（要 sudo/root）。

## 不要做的事

- 不要指望改 `PLAYWRIGHT_DOWNLOAD_HOST` —— agent-browser **不是** Playwright 驱动那套变量。
- 不要把整份上游 README 机翻当「部署教程」；安装成功标准以 `doctor` + 本仓 `smoke.sh` 为准。
