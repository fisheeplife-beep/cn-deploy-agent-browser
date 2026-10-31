#!/usr/bin/env bash
# Minimal end-to-end check: open example.com → title → snapshot → screenshot → close
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ missing $1"; exit 1; }; }
need agent-browser

OUT_DIR="${1:-./examples}"
mkdir -p "$OUT_DIR"
SHOT="$OUT_DIR/smoke-screenshot.png"

cleanup() { agent-browser close >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "→ doctor --offline --quick"
agent-browser doctor --offline --quick

echo "→ open https://example.com"
agent-browser open https://example.com

title=$(agent-browser get title)
url=$(agent-browser get url)
echo "   title: $title"
echo "   url:   $url"

echo "→ snapshot -i"
agent-browser snapshot -i | head -20

echo "→ screenshot $SHOT"
agent-browser screenshot "$SHOT"

echo "→ close"
agent-browser close
trap - EXIT

echo
echo "✓ smoke OK"
echo "  title should contain 'Example'"
echo "  screenshot: $SHOT"
