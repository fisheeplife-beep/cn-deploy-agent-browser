#!/usr/bin/env bash
# Preflight for installing / using agent-browser on a CN-friendly host.
set -euo pipefail

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

say "=== agent-browser CN preflight ==="
say ""

# Node (npm global / project install path)
if command -v node >/dev/null 2>&1; then
  nv=$(node -v | sed 's/^v//')
  major=${nv%%.*}
  if [[ "$major" -ge 24 ]]; then
    pass "Node.js $nv (>= 24 recommended for npm package engines)"
  elif [[ "$major" -ge 18 ]]; then
    warn_ "Node.js $nv — package engines declare >=24; older Node may still run the shipped native binary, but prefer Node 24+"
  else
    fail "Node.js $nv — too old; install Node 24+ for npm install -g agent-browser"
  fi
else
  warn_ "Node.js not found — use Homebrew/Cargo path, or install Node 24+ for npm"
fi

if command -v npm >/dev/null 2>&1; then
  reg=$(npm config get registry 2>/dev/null || true)
  say "   npm registry: ${reg:-unknown}"
  if [[ "$reg" == *"npmmirror.com"* ]]; then
    pass "npm registry points at npmmirror (good for CN)"
  elif [[ "$reg" == *"registry.npmjs.org"* ]]; then
    warn_ "npm registry is npmjs.org — OK if reachable; on timeout: npm config set registry https://registry.npmmirror.com"
  else
    warn_ "Custom npm registry ($reg)"
  fi
fi

if command -v cargo >/dev/null 2>&1; then
  pass "cargo available (optional: cargo install agent-browser)"
else
  say "   (cargo not found — skip Rust install path)"
fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew available (optional: brew install agent-browser)"
else
  say "   (Homebrew not found — macOS users can install later)"
fi

# Existing browsers
chrome_found=0
for c in google-chrome google-chrome-stable chromium chromium-browser \
         /usr/bin/google-chrome /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome; do
  if command -v "$c" >/dev/null 2>&1 || [[ -x "$c" ]]; then
    pass "Found browser candidate: $c"
    chrome_found=1
    break
  fi
done
if [[ "$chrome_found" -eq 0 ]]; then
  warn_ "No system Chrome/Chromium detected — you will need agent-browser install (Chrome for Testing) or set AGENT_BROWSER_EXECUTABLE_PATH"
fi

if command -v ffmpeg >/dev/null 2>&1; then
  pass "ffmpeg present (needed for record *.webm/*.mp4)"
else
  warn_ "ffmpeg missing — video record commands will fail; screenshots/snapshot still work"
fi

# Disk
if df -P "$HOME" >/dev/null 2>&1; then
  avail_kb=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [[ "$avail_gb" -ge 3 ]]; then
    pass "Home disk free ~${avail_gb} GB (Chrome for Testing ~200MB zip + unpack)"
  else
    warn_ "Home disk free ~${avail_gb} GB — may be tight for Chrome download"
  fi
fi

probe() {
  local name="$1" url="$2"
  # Prefer HEAD so large artifacts (e.g. Chrome zip) are not downloaded.
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 -I -L "$url" 2>/dev/null || true)
  if [[ ! "$code" =~ ^[0-9]{3}$ ]]; then
    code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 8 -L --range 0-0 "$url" 2>/dev/null || true)
  fi
  if [[ ! "$code" =~ ^[0-9]{3}$ ]]; then
    code="000"
  fi
  if [[ "$code" =~ ^(200|301|302|401|403|404|405)$ ]]; then
    pass "Reachable: $name (HTTP $code)"
  else
    warn_ "Unreachable or slow: $name ($url → HTTP $code)"
  fi
}

say ""
say "--- network (best-effort) ---"
probe "npmjs.org/agent-browser" "https://registry.npmjs.org/agent-browser"
probe "npmmirror/agent-browser" "https://registry.npmmirror.com/agent-browser"
probe "Chrome for Testing CDN (Google)" "https://storage.googleapis.com/chrome-for-testing-public/"
probe "npmmirror chrome-for-testing zip" "https://cdn.npmmirror.com/binaries/chrome-for-testing/156.0.8078.80/linux64/chrome-linux64.zip"
probe "chrome-for-testing JSON" "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
probe "agent-browser.dev" "https://agent-browser.dev/"
probe "GitHub upstream" "https://github.com/vercel-labs/agent-browser"

say ""
say "=== summary: ${ok} ok / ${warn} warn / ${bad} bad ==="
if [[ "$bad" -gt 0 ]]; then
  exit 1
fi
exit 0
