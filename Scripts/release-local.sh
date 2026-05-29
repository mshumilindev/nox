#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SOURCE_APP="${REPO_ROOT}/.build/xcode-derived-data/Build/Products/Release/Nox.app"

printf '[release-local] Building and installing Nox as a local Release app.\n'
"${SCRIPT_DIR}/build-release.sh"
"${SCRIPT_DIR}/install-app.sh" "$@" "${SOURCE_APP}"
printf '[release-local] Complete. Use /Applications/Nox.app for normal daily launches.\n'
