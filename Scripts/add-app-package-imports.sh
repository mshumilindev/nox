#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "${ROOT}/Scripts/fix-swift-imports.py" --add-nox-packages "${ROOT}/Apps/NoxMac/Nox"
