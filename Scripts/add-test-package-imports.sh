#!/usr/bin/env bash
# Adds only the package imports a test file needs (run fix-swift-imports after manual edits).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "${ROOT}/Scripts/fix-swift-imports.py" "${ROOT}/NoxTests"
echo "Deduplicated imports under NoxTests"
