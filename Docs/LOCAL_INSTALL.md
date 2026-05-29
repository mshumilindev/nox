# Local Release Install

Nox is designed for normal daily use as an installed macOS menu bar app at `/Applications/Nox.app`. Xcode remains useful for development, but an installed Release app gives Nox a stable executable path for macOS permissions, login launch, and ordinary Spotlight/Finder launches.

## Build And Install

From the repository root:

```bash
./scripts/release-local.sh
```

The repository stores scripts in `Scripts/`; the lowercase command above works on the standard case-insensitive macOS filesystem. `./Scripts/release-local.sh` is the canonical spelling in the checkout.

The command:

1. Builds the `Nox` scheme in `Release` configuration with `xcodebuild`.
2. Uses `Nox.xcodeproj` and deterministic DerivedData at `.build/xcode-derived-data`.
3. Validates `.build/xcode-derived-data/Build/Products/Release/Nox.app`.
4. Stages the new bundle inside `/Applications`.
5. Quits only running Nox app processes, if any.
6. Renames the staged app into `/Applications/Nox.app`, restoring the previous bundle if replacement cannot complete.
7. Launches the installed app and verifies it is running from `/Applications`.

To run the steps separately:

```bash
./Scripts/build-release.sh
./Scripts/install-app.sh
```

If the scheme name changes from `Nox`, update the scripts or temporarily pass `NOX_SCHEME=<scheme> ./Scripts/build-release.sh`.

The install script requires write access to `/Applications`. It fails clearly rather than installing into another location.
If `/Applications` requires administrator authorization on your Mac, rerun:

```bash
./scripts/release-local.sh --authorize
```

That option requests macOS authorization only for replacing the app bundle, then launches Nox in your normal logged-in user session. Do not run the app-launching workflow with `sudo`.

## Daily Use

After installation, open Nox from `/Applications`, Spotlight, or Launch at Login. Do not use the Release install script as the everyday launcher; use it when installing a new local build.

Nox remains a menu-bar-only app (`LSUIElement`) and does not rely on Xcode, Cursor, LLDB, or `lldb-rpc-server` after launch.

To verify a normal installed launch:

```bash
pgrep -fl '/Applications/Nox.app/Contents/MacOS/Nox'
```

Activity Monitor should likewise show `Nox` running as an ordinary app process after Xcode and editor applications are closed.

## Launch At Login

Nox uses Apple's modern `SMAppService.mainApp` login-item registration.

1. Install and open `/Applications/Nox.app`.
2. Open the Nox menu-bar item and choose **Settings...**.
3. Turn **Launch Nox at login** on or off.
4. If macOS requests approval, use **Open Login Items Settings** and allow Nox under **General > Login Items**.

Login launch starts the installed main app directly. It does not use a debugger, helper copy, or development window. Normal Launch Services behavior keeps one running main app instance when it is opened again.

## Local Data

Nox is sandboxed with bundle identifier `dev.nox.Nox`. Durable local data is stored at:

```text
~/Library/Containers/dev.nox.Nox/Data/Library/Application Support/Nox/
```

The persistence audit covers:

| Data | Location |
| --- | --- |
| Timeline, sessions, semantic memory, preferences, connector state, reflections, rollups | `Nox/timeline.db` |
| Presence Mesh public identity, trusted nodes, artwork cache | `Nox/PresenceMesh/` |
| Presence Mesh private signing keys | macOS Keychain |
| Exported pairing invite file | Temporary file created only for sharing, not durable collected data |

Replacing `/Applications/Nox.app` does not touch the container or Keychain. The install scripts never delete, migrate, or rewrite user data.

## Uninstall And Reset

To remove only the installed app:

```bash
rm -rf /Applications/Nox.app
```

This leaves local Nox data intact.

To fully reset local data, quit Nox first and separately remove its sandbox container:

```bash
rm -rf ~/Library/Containers/dev.nox.Nox
```

Removing the container is destructive and is not part of installation or updates. Keychain items associated with Presence Mesh may also need deletion through Keychain Access if a full identity reset is desired.
