#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

write_pkg() {
  local name="$1"
  shift
  local deps=("$@")
  local tmp
  tmp="$(mktemp)"
  cat > "${tmp}" <<'HEADER'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
HEADER
  {
    echo "    name: \"${name}\","
    echo "    platforms: ["
    echo "        .macOS(.v14),"
    echo "        .iOS(.v17),"
    echo "        .watchOS(.v10),"
    echo "        .tvOS(.v17),"
    echo "        .visionOS(.v1),"
    echo "    ],"
    echo "    products: ["
    echo "        .library(name: \"${name}\", targets: [\"${name}\"]),"
    echo "    ],"
    if ((${#deps[@]} > 0)); then
      echo "    dependencies: ["
      for d in "${deps[@]}"; do
        echo "        .package(path: \"../${d}\"),"
      done
      echo "    ],"
    else
      echo "    dependencies: [],"
    fi
    echo "    targets: ["
    echo "        .target("
    echo "            name: \"${name}\","
    if ((${#deps[@]} > 0)); then
      echo "            dependencies: ["
      for d in "${deps[@]}"; do
        echo "                .product(name: \"${d}\", package: \"${d}\"),"
      done
      echo "            ]"
    else
      echo "            dependencies: []"
    fi
    echo "        ),"
    echo "        .testTarget("
    echo "            name: \"${name}Tests\","
    echo "            dependencies: [\"${name}\"]"
    echo "        ),"
    echo "    ]"
    echo ")"
  } >> "${tmp}"
  mv "${tmp}" "${ROOT}/Packages/${name}/Package.swift"
}

write_pkg NoxCore
write_pkg NoxPlatformContracts
write_pkg NoxContextCore NoxCore
write_pkg NoxSemanticCore NoxCore NoxContextCore
write_pkg NoxMemoryCore NoxCore NoxContextCore NoxSemanticCore
write_pkg NoxContinuityCore NoxCore NoxContextCore NoxMemoryCore NoxSemanticCore
write_pkg NoxBehavioralIntelligenceCore NoxCore NoxContextCore NoxMemoryCore NoxContinuityCore
write_pkg NoxAmbientUtilityCore NoxCore NoxContinuityCore NoxBehavioralIntelligenceCore NoxMemoryCore
write_pkg NoxSystemStateCore NoxCore NoxAmbientUtilityCore
write_pkg NoxObservatoryCore NoxCore NoxMemoryCore NoxBehavioralIntelligenceCore NoxContinuityCore NoxContextCore
write_pkg NoxPresenceCore NoxCore NoxMemoryCore
write_pkg NoxDesignCore NoxCore
echo "Updated manifests"
