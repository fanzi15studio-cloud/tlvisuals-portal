#!/usr/bin/env bash
# Compile (si nécessaire) puis lance tesla-display.
# Usage : ./run.sh [options tesla-display]   —  ./run.sh --help pour la liste.
set -euo pipefail

cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ tesla-display ne fonctionne que sur macOS (ScreenCaptureKit)." >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "❌ Swift est introuvable. Installez les outils en ligne de commande :" >&2
  echo "   xcode-select --install" >&2
  exit 1
fi

echo "▶︎ Compilation…"
swift build -c release

exec .build/release/tesla-display "$@"
