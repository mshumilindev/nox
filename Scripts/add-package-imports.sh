#!/usr/bin/env bash
# Adds `import <Dep>` to package sources based on Package.swift dependencies.
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

add_imports() {
  local pkg="$1"
  shift
  local deps=("$@")
  local dir="${ROOT}/Packages/${pkg}/Sources/${pkg}"
  [[ -d "${dir}" ]] || return 0
  while IFS= read -r -d '' f; do
    local text
    text="$(cat "${f}")"
    local header="import Foundation"
    for d in "${deps[@]}"; do
      grep -q "import ${d}" "${f}" && continue
      if echo "${text}" | grep -qE "(Nox[A-Z][A-Za-z0-9_]*)"; then
        header="${header}"$'\n'"import ${d}"
      fi
    done
    if ! grep -q '^import Foundation' "${f}"; then
      header="${header}"$'\n'"${text}"
      echo "${header}" > "${f}"
    else
      for d in "${deps[@]}"; do
        grep -q "import ${d}" "${f}" || sed -i '' "/^import Foundation/a\\
import ${d}
" "${f}"
      done
    fi
  done < <(find "${dir}" -name '*.swift' -print0)
}

add_imports NoxContextCore NoxCore
add_imports NoxSemanticCore NoxCore NoxContextCore
add_imports NoxMemoryCore NoxCore NoxContextCore NoxSemanticCore
add_imports NoxContinuityCore NoxCore NoxContextCore NoxMemoryCore NoxSemanticCore
add_imports NoxBehavioralIntelligenceCore NoxCore NoxContextCore NoxMemoryCore NoxContinuityCore NoxSemanticCore
add_imports NoxAmbientUtilityCore NoxCore NoxContinuityCore NoxBehavioralIntelligenceCore NoxMemoryCore NoxSemanticCore
add_imports NoxSystemStateCore NoxCore NoxAmbientUtilityCore
add_imports NoxObservatoryCore NoxCore NoxContextCore NoxMemoryCore NoxContinuityCore NoxSemanticCore NoxBehavioralIntelligenceCore
add_imports NoxPresenceCore NoxCore
add_imports NoxDesignCore NoxCore
echo "Package imports added"
