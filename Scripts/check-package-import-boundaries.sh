#!/usr/bin/env bash
# Fails if forbidden imports appear in shared package Sources.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_ROOT="${ROOT}/Packages"

FORBIDDEN=(
  'import AppKit'
  'import SwiftUI'
  'import SQLite3'
  'import EventKit'
  'import UserNotifications'
  'import CoreBluetooth'
  'import Network'
  'import ApplicationServices'
  'import IOKit'
  'import Cocoa'
  'import Combine'
)

if [[ ! -d "${PACKAGES_ROOT}" ]]; then
  echo "No Packages/ directory — nothing to check."
  exit 0
fi

failed=0
while IFS= read -r -d '' file; do
  for pattern in "${FORBIDDEN[@]}"; do
    if grep -qF "${pattern}" "${file}" 2>/dev/null; then
      echo "FORBIDDEN: ${pattern} in ${file}"
      failed=1
    fi
  done
done < <(find "${PACKAGES_ROOT}" -path '*/Sources/*' -name '*.swift' -print0)

if [[ "${failed}" -ne 0 ]]; then
  echo "Package import boundary check failed."
  exit 1
fi

echo "Package import boundary check passed."
