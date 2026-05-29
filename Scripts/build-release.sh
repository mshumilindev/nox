#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCHEME="${NOX_SCHEME:-Nox}"
readonly CONFIGURATION="Release"
readonly DERIVED_DATA_PATH="${NOX_DERIVED_DATA_PATH:-${REPO_ROOT}/.build/xcode-derived-data}"
readonly PRODUCT_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/Nox.app"

log() {
  printf '[build-release] %s\n' "$*"
}

fail() {
  printf '[build-release] ERROR: %s\n' "$*" >&2
  exit 1
}

cd "${REPO_ROOT}"

shopt -s nullglob
workspaces=("${REPO_ROOT}"/*.xcworkspace)
projects=("${REPO_ROOT}"/*.xcodeproj)
shopt -u nullglob

if ((${#workspaces[@]} == 1)); then
  container_flag="-workspace"
  container_path="${workspaces[0]}"
elif ((${#workspaces[@]} > 1)); then
  fail "More than one root-level .xcworkspace was found. Set up a single build workspace or update this script explicitly."
elif ((${#projects[@]} == 1)); then
  container_flag="-project"
  container_path="${projects[0]}"
elif ((${#projects[@]} == 0)); then
  fail "No root-level .xcworkspace or .xcodeproj was found."
else
  fail "More than one root-level .xcodeproj was found. Update this script with the intended project."
fi

log "Repository: ${REPO_ROOT}"
log "Build container: ${container_flag} ${container_path}"
log "Scheme: ${SCHEME}"
log "Configuration: ${CONFIGURATION}"
log "DerivedData: ${DERIVED_DATA_PATH}"

xcodebuild \
  "${container_flag}" "${container_path}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

if [[ ! -d "${PRODUCT_PATH}" ]]; then
  fail "Release build completed, but the expected app bundle was not found at ${PRODUCT_PATH}."
fi

if [[ ! -x "${PRODUCT_PATH}/Contents/MacOS/Nox" ]]; then
  fail "The bundle at ${PRODUCT_PATH} does not contain an executable Nox binary."
fi

log "Build output: ${PRODUCT_PATH}"
printf '%s\n' "${PRODUCT_PATH}"
