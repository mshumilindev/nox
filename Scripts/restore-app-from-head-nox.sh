#!/usr/bin/env bash
# Restore Apps/NoxMac/Nox sources from HEAD:Nox/ where they existed before the move.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${ROOT}/Apps/NoxMac/Nox"

restored=0
skipped=0
while IFS= read -r -d '' f; do
  rel="${f#${APP}/}"
  if git show "HEAD:Nox/${rel}" >/dev/null 2>&1; then
    git show "HEAD:Nox/${rel}" > "${f}"
    restored=$((restored + 1))
  else
    skipped=$((skipped + 1))
  fi
done < <(find "${APP}" -name '*.swift' -print0)

echo "Restored ${restored} files from HEAD:Nox/, skipped ${skipped} (new-only)"
