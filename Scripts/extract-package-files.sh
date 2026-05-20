#!/usr/bin/env bash
# Moves Foundation-only Nox/Core files into Packages per PLATFORM_MIGRATION.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

move_dir() {
  local src="$1" dest_pkg="$2" dest_sub="${3:-}"
  local dest="${ROOT}/Packages/${dest_pkg}/Sources/${dest_pkg}"
  [[ -n "${dest_sub}" ]] && dest="${dest}/${dest_sub}"
  mkdir -p "${dest}"
  if [[ -d "${src}" ]]; then
    for f in "${src}"/*.swift; do
      [[ -f "${f}" ]] || continue
      local base
      base="$(basename "${f}")"
      case "${base}" in
        *Store.swift|NoxSQLite*) continue ;;
      esac
      if grep -qE 'import (AppKit|SwiftUI|SQLite3|EventKit|UserNotifications|CoreBluetooth|Network|ApplicationServices|IOKit|Cocoa|Combine)' "${f}" 2>/dev/null; then
        continue
      fi
      [[ -f "${dest}/${base}" ]] && continue
      git mv "${f}" "${dest}/" 2>/dev/null || mv "${f}" "${dest}/"
    done
  fi
}

move_file() {
  local src="$1" dest_pkg="$2" dest_path="$3"
  [[ -f "${src}" ]] || return 0
  if grep -qE 'import (AppKit|SwiftUI|SQLite3|EventKit|UserNotifications|CoreBluetooth|Network|ApplicationServices|IOKit)' "${src}" 2>/dev/null; then
    return 0
  fi
  local dest="${ROOT}/Packages/${dest_pkg}/Sources/${dest_pkg}/${dest_path}"
  mkdir -p "$(dirname "${dest}")"
  [[ -f "${dest}" ]] && return 0
  git mv "${src}" "${dest}" 2>/dev/null || mv "${src}" "${dest}"
}

echo "Extracting NoxDesignCore (spacing only)..."
move_file "Nox/Core/DesignSystem/NoxSpacing.swift" "NoxDesignCore" "NoxSpacing.swift"

echo "Extracting NoxSystemStateCore..."
move_dir "Nox/Core/SystemState" "NoxSystemStateCore"
rm -f Packages/NoxSystemStateCore/Sources/NoxSystemStateCore/NoxSystemStateProvider.swift \
  Packages/NoxSystemStateCore/Sources/NoxSystemStateCore/NoxSystemActionExecutor.swift \
  Packages/NoxSystemStateCore/Sources/NoxSystemStateCore/NoxCaffeinateController.swift 2>/dev/null || true
[[ -f Nox/Core/SystemState/NoxSystemStateProvider.swift ]] || git checkout HEAD -- Nox/Core/SystemState/NoxSystemStateProvider.swift 2>/dev/null || true

echo "Done extract pass."
