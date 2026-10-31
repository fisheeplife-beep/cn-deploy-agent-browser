# cn-deploy-agent-browser

Chinese, follow-along **deployment companion** for [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) — not an official fork, and not a verbatim copy of upstream docs.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

### What you get

- Preflight / install / Chrome (incl. **npmmirror** fallback for Linux) / smoke scripts
- China network notes (`docs/china-network.md`)
- Example doctor + `example.com` smoke outputs

### Verification snapshot (author box, 2026-10-31, Asia/Shanghai)

| Path | Status |
|------|--------|
| `npm install -g agent-browser@0.41.0` on **Node 24.11.0** | **Verified** |
| `agent-browser install` (Chrome for Testing 156.0.8078.80) | **Verified** |
| `agent-browser doctor` (incl. headless launch) | **Verified** — 10 pass |
| Smoke: open `https://example.com` → title / snapshot / screenshot / close | **Verified** |
| `agent-browser read https://example.com` (no Chrome) | **Verified** |
| `install-chrome.sh mirror` (npmmirror zip) | **Script ready; full re-download not re-run after official install succeeded** |
| `install --with-deps`, Homebrew, Cargo | **Not verified** on this host |
| AI `chat` / cloud browser providers | **Not verified** (no API keys) |

### Quick start

```bash
./scripts/preflight.sh
./scripts/install-cli.sh          # Node >= 24
./scripts/install-chrome.sh       # auto → official, else Linux mirror
./scripts/smoke.sh
```

Upstream: https://github.com/vercel-labs/agent-browser · Docs: https://agent-browser.dev  
License for this companion: [MIT](./LICENSE)
