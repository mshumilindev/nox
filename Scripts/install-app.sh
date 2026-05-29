#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DEFAULT_SOURCE_APP="${REPO_ROOT}/.build/xcode-derived-data/Build/Products/Release/Nox.app"
readonly INSTALL_PARENT="/Applications"
readonly INSTALL_APP="${INSTALL_PARENT}/Nox.app"
readonly BUNDLE_IDENTIFIER="dev.nox.Nox"
readonly PROCESS_PATTERN='/Nox[.]app/Contents/MacOS/Nox$'

authorize_install=false
privileged_replace=false
if [[ "${1:-}" == "--authorize" ]]; then
  authorize_install=true
  shift
elif [[ "${1:-}" == "--privileged-replace" ]]; then
  privileged_replace=true
  shift
fi
readonly SOURCE_APP="${1:-${DEFAULT_SOURCE_APP}}"

staging_dir=""
authorization_dir=""

log() {
  printf '[install-app] %s\n' "$*"
}

fail() {
  printf '[install-app] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${staging_dir}" && -d "${staging_dir}" ]]; then
    rm -rf "${staging_dir}"
  fi
  if [[ -n "${authorization_dir}" && -d "${authorization_dir}" ]]; then
    rm -rf "${authorization_dir}"
  fi
}

trap cleanup EXIT

validate_source_app() {
  if [[ ! -d "${SOURCE_APP}" ]]; then
    fail "Release app bundle not found at ${SOURCE_APP}. Run Scripts/build-release.sh first."
  fi

  if [[ ! -x "${SOURCE_APP}/Contents/MacOS/Nox" ]]; then
    fail "Source bundle does not contain an executable Nox binary: ${SOURCE_APP}"
  fi
}

stop_running_nox() {
  local running_pids
  local remaining_pids
  running_pids="$(pgrep -f "${PROCESS_PATTERN}" || true)"
  if [[ -n "${running_pids}" ]]; then
    log "Stopping currently running Nox app instance(s): ${running_pids//$'\n'/, }"
    osascript -e "tell application id \"${BUNDLE_IDENTIFIER}\" to quit" >/dev/null 2>&1 || true

    for _ in {1..20}; do
      if ! pgrep -f "${PROCESS_PATTERN}" >/dev/null 2>&1; then
        break
      fi
      sleep 0.25
    done

    remaining_pids="$(pgrep -f "${PROCESS_PATTERN}" || true)"
    if [[ -n "${remaining_pids}" ]]; then
      log "Nox did not finish quitting in time; sending TERM only to remaining Nox process(es): ${remaining_pids//$'\n'/, }"
      while IFS= read -r pid; do
        [[ -n "${pid}" ]] && kill -TERM "${pid}"
      done <<< "${remaining_pids}"
    fi
  else
    log "No running Nox app instance needs to be stopped."
  fi
}

replace_app_bundle() {
  if [[ ! -d "${INSTALL_PARENT}" || ! -w "${INSTALL_PARENT}" ]]; then
    fail "${INSTALL_PARENT} is not writable. Install requires permission to replace ${INSTALL_APP}; rerun with --authorize to approve only the app-bundle replacement."
  fi

  staging_dir="$(mktemp -d "${INSTALL_PARENT}/.Nox.local-install.XXXXXX")"
  local staged_app="${staging_dir}/Nox.app"
  local previous_app="${staging_dir}/Nox.previous.app"

  log "Staging latest Release bundle in ${staging_dir}"
  ditto "${SOURCE_APP}" "${staged_app}"

  if [[ -e "${INSTALL_APP}" ]]; then
    log "Moving existing app aside during replacement."
    mv "${INSTALL_APP}" "${previous_app}"
  fi

  if ! mv "${staged_app}" "${INSTALL_APP}"; then
    log "Replacement failed; restoring previous app bundle."
    if [[ -e "${previous_app}" ]]; then
      mv "${previous_app}" "${INSTALL_APP}"
    fi
    fail "Could not move the new bundle into ${INSTALL_APP}."
  fi

  if [[ -e "${previous_app}" ]]; then
    rm -rf "${previous_app}"
  fi

  log "Installed Release app at ${INSTALL_APP}"
  log "Persistent user data was not touched (sandbox Application Support container remains in place)."
}

launch_installed_app() {
  log "Launching ${INSTALL_APP}"
  open "${INSTALL_APP}"

  for _ in {1..20}; do
    if pgrep -f '/Applications/Nox[.]app/Contents/MacOS/Nox$' >/dev/null 2>&1; then
      log "Launch succeeded: Nox is running from /Applications."
      return
    fi
    sleep 0.25
  done

  fail "The app was installed, but a running /Applications/Nox.app process was not observed after launch."
}

validate_source_app
log "Source app: ${SOURCE_APP}"
log "Installed app: ${INSTALL_APP}"

if "${privileged_replace}"; then
  replace_app_bundle
  exit 0
fi

if [[ ! -w "${INSTALL_PARENT}" && "${authorize_install}" != true ]]; then
  fail "${INSTALL_PARENT} is not writable. Install requires permission to replace ${INSTALL_APP}; rerun with --authorize to approve only the app-bundle replacement."
fi

stop_running_nox

if [[ -w "${INSTALL_PARENT}" ]]; then
  replace_app_bundle
elif "${authorize_install}"; then
  authorization_dir="$(mktemp -d "/private/tmp/Nox.local-authorize.XXXXXX")"
  authorized_script="${authorization_dir}/install-app.sh"
  authorized_source_app="${authorization_dir}/Nox.app"
  log "Preparing authorization staging source in ${authorization_dir}"
  ditto "${SOURCE_APP}" "${authorized_source_app}"
  cp "${SCRIPT_DIR}/install-app.sh" "${authorized_script}"
  chmod +x "${authorized_script}"
  log "Requesting administrator authorization for the /Applications bundle replacement only."
  osascript - "${authorized_script}" "${authorized_source_app}" <<'APPLESCRIPT'
on run argv
  set scriptPath to item 1 of argv
  set sourcePath to item 2 of argv
  set commandText to quoted form of scriptPath & " --privileged-replace " & quoted form of sourcePath
  do shell script commandText with administrator privileges with prompt "Nox needs permission to install its Release app in /Applications."
end run
APPLESCRIPT
fi

launch_installed_app
