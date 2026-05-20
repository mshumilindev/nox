#!/usr/bin/env bash
# Usage: Scripts/scaffold-nox-package.sh NoxSemanticCore "NoxCore NoxContextCore"
set -euo pipefail
NAME="${1:?Package name required}"
DEPS="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="${ROOT}/Packages/${NAME}"
if [[ -d "${PKG}" ]]; then
  echo "Package already exists: ${PKG}"
  exit 1
fi
mkdir -p "${PKG}/Sources/${NAME}" "${PKG}/Tests/${NAME}Tests"
DEPS_ARRAY=""
if [[ -n "${DEPS}" ]]; then
  for d in ${DEPS}; do
    DEPS_ARRAY="${DEPS_ARRAY}
        .product(name: \"${d}\", package: \"${d}\"),"
  done
fi
DEPS_PKG=""
if [[ -n "${DEPS}" ]]; then
  for d in ${DEPS}; do
    DEPS_PKG="${DEPS_PKG}
        .package(path: \"../${d}\"),"
  done
fi
cat > "${PKG}/Package.swift" <<EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "${NAME}",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "${NAME}", targets: ["${NAME}"]),
    ],
    dependencies: [${DEPS_PKG}
    ],
    targets: [
        .target(
            name: "${NAME}",
            dependencies: [${DEPS_ARRAY}
            ]
        ),
        .testTarget(
            name: "${NAME}Tests",
            dependencies: ["${NAME}"]
        ),
    ]
)
EOF
cat > "${PKG}/Sources/${NAME}/${NAME}Placeholder.swift" <<EOF
import Foundation

/// Placeholder until domain files are extracted into ${NAME}.
public enum ${NAME}Placeholder: Sendable {}
EOF
cat > "${PKG}/Tests/${NAME}Tests/${NAME}Tests.swift" <<EOF
import ${NAME}
import Testing

@Test func packageSmokeTest() {
    #expect(true)
}
EOF
echo "Created ${PKG}"
