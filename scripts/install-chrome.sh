#!/usr/bin/env bash
# Install Chrome for agent-browser.
# Default: `agent-browser install` (Google CDN).
# CN fallback: download linux64 zip from npmmirror into ~/.agent-browser/browsers/
set -euo pipefail

MODE="${1:-auto}"   # auto | official | mirror | system
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"

die() { echo "❌ $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need agent-browser
need curl
need python3

if [[ "$MODE" == "system" ]]; then
  for c in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$c" >/dev/null 2>&1; then
      path=$(command -v "$c")
      echo "export AGENT_BROWSER_EXECUTABLE_PATH=$path"
      echo "✓ Use system browser: $path"
      echo "  Add to shell: export AGENT_BROWSER_EXECUTABLE_PATH=$path"
      exit 0
    fi
  done
  die "No system Chrome/Chromium found"
fi

# Linux deps hint
if [[ "$PLATFORM" == "Linux" && "${WITH_DEPS:-0}" == "1" ]]; then
  echo "→ agent-browser install --with-deps"
  agent-browser install --with-deps || true
fi

try_official() {
  echo "→ agent-browser install  (Chrome for Testing via Google CDN)"
  agent-browser install
}

# Resolve Stable version + linux64 zip name from GoogleChromeLabs JSON (small JSON; often OK in CN)
resolve_version() {
  python3 - <<'PY'
import json, urllib.request
url = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
with urllib.request.urlopen(url, timeout=20) as r:
    data = json.load(r)
ver = data["channels"]["Stable"]["version"]
print(ver)
PY
}

try_mirror() {
  need unzip
  [[ "$(uname -s)" == "Linux" ]] || die "npmmirror zip helper currently targets Linux x64; on macOS use official install or system Chrome"
  [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]] || die "mirror helper expects x86_64 (got $ARCH)"

  ver="${CHROME_FOR_TESTING_VERSION:-}"
  if [[ -z "$ver" ]]; then
    echo "→ resolve Stable version from chrome-for-testing JSON"
    ver=$(resolve_version)
  fi
  mirror_url="https://cdn.npmmirror.com/binaries/chrome-for-testing/${ver}/linux64/chrome-linux64.zip"
  dest_dir="${HOME}/.agent-browser/browsers/chrome-${ver}"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  echo "→ download $mirror_url"
  curl -fL --retry 3 --retry-delay 2 -o "$tmp/chrome-linux64.zip" "$mirror_url"
  echo "→ unpack to $dest_dir"
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  unzip -q "$tmp/chrome-linux64.zip" -d "$tmp/out"
  # zip root is chrome-linux64/
  if [[ -d "$tmp/out/chrome-linux64" ]]; then
    # move contents (including hidden) 
    shopt -s dotglob
    mv "$tmp/out/chrome-linux64"/* "$dest_dir/"
    shopt -u dotglob
  else
    die "unexpected zip layout"
  fi
  chmod +x "$dest_dir/chrome" "$dest_dir/chrome_crashpad_handler" 2>/dev/null || true
  echo "✓ Chrome for Testing $ver at $dest_dir/chrome"
  echo "  agent-browser should auto-detect this cache; if not:"
  echo "  export AGENT_BROWSER_EXECUTABLE_PATH=$dest_dir/chrome"
}

case "$MODE" in
  official) try_official ;;
  mirror) try_mirror ;;
  auto)
    if try_official; then
      exit 0
    fi
    echo "⚠️  Official install failed — trying npmmirror zip (Linux x64)..."
    try_mirror
    ;;
  *) die "usage: $0 [auto|official|mirror|system]" ;;
esac

echo
echo "Next: agent-browser doctor && ./scripts/smoke.sh"
