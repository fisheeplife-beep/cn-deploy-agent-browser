#!/usr/bin/env bash
# Post-install verification wrapper
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v agent-browser >/dev/null 2>&1; then
  echo "❌ agent-browser not on PATH — run ./scripts/install-cli.sh first"
  exit 1
fi

echo "=== version ==="
agent-browser --version

echo
echo "=== doctor ==="
agent-browser doctor "$@"

echo
echo "=== smoke ==="
"$ROOT/scripts/smoke.sh" "$ROOT/examples"
