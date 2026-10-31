#!/usr/bin/env bash
# Install agent-browser CLI via npm (recommended path).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

need_node_major=24
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Need Node.js >= ${need_node_major}. Install from https://nodejs.org/ or https://npmmirror.com/mirrors/node/"
  exit 1
fi
nv=$(node -v | sed 's/^v//')
major=${nv%%.*}
if [[ "$major" -lt "$need_node_major" ]]; then
  echo "⚠️  Node $nv < ${need_node_major}. Upstream engines require >=24; continuing anyway may fail."
  echo "    Prefer upgrading Node, then re-run."
fi

REG_ARGS=()
# Prefer official registry for package resolution if mirror returns odd results;
# users in CN can still use npmmirror — both carried agent-browser@0.41.0 in our checks.
if [[ "${FORCE_NPMJS:-}" == "1" ]]; then
  REG_ARGS=(--registry https://registry.npmjs.org)
fi

echo "→ npm install -g agent-browser@${AGENT_BROWSER_VERSION:-latest} ${REG_ARGS[*]:-}"
npm install -g "agent-browser@${AGENT_BROWSER_VERSION:-latest}" "${REG_ARGS[@]}"

if ! command -v agent-browser >/dev/null 2>&1; then
  echo "❌ agent-browser not on PATH after install."
  echo "   Check: npm prefix -g  and  echo \$PATH"
  echo "   Common fix: export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
  exit 1
fi

echo "✓ $(agent-browser --version 2>/dev/null || echo agent-browser installed)"
echo
echo "Next:"
echo "  1) ./scripts/install-chrome.sh     # Chrome for Testing (or use system Chrome)"
echo "  2) agent-browser doctor"
echo "  3) ./scripts/smoke.sh"
