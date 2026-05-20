# Platform boundary migration

macOS remains the canonical Nox node. Domain types live in Swift packages; macOS adapters, SQLite, mesh, and UI live under `Apps/NoxMac/Nox`. **No runtime behavior or DB schema changes** in this migration.

**Guidance**: `.cursor/rules/nox-platform-boundaries.mdc`, `nox-shared-packages.mdc`, `nox-macos-adapters.mdc`. Overview: `Docs/PLATFORM_ARCHITECTURE.md`.

## Baseline

| Check | Command | Status |
|-------|---------|--------|
| Debug build | `xcodebuild -scheme Nox -destination 'platform=macOS' -configuration Debug build` | ✅ 2026-05-20 |
| Unit tests | `xcodebuild … test -only-testing:NoxTests` | ✅ 2026-05-20 |
| Package tests | `swift test --package-path Packages/<Name>` | ✅ Core, Contracts, Context, Semantic, Memory, Continuity, Presence, Observatory, Design (+ placeholder cores) |
| Import guard | `Scripts/check-package-import-boundaries.sh` | ✅ |
| Explicit app imports | `Scripts/add-app-package-imports.sh`, `Scripts/add-test-package-imports.sh` | ✅ (replaces `NoxPackageExports.swift`) |

Note: `NoxUITests` may fail independently; gate on `NoxTests` + app build.

## Layout (current)

```
Packages/
  NoxPlatformContracts/   # Foundation protocols
  NoxCore/                # Primitives, trust, events, permissions
  NoxContextCore/         # Context models & classifiers
  NoxSemanticCore/        # Semantic arcs, framing types
  NoxMemoryCore/          # Memory domain types (not SQLite stores)
  NoxContinuityCore/      # Continuity thread types
  NoxPresenceCore/        # Mesh crypto, pairing types
  NoxObservatoryCore/     # Observatory signals & buckets
  NoxDesignCore/          # Spacing, tokens (Foundation)
  NoxBehavioralIntelligenceCore/  # placeholder target
  NoxAmbientUtilityCore/          # placeholder target
  NoxSystemStateCore/             # placeholder target
Apps/
  NoxMac/
    Nox/                  # Canonical macOS app (Xcode synchronized group)
    README.md
NoxTests/
  Mac/                    # macOS integration suites (one file per struct)
  *.swift                 # mac-only tests (stores, mesh invite, artwork)
```

## Phase checklist

- [x] **Phase 0** — Inventory, baseline, migration doc, import-boundary script
- [x] **Phase 1** — `NoxPlatformContracts`
- [x] **Phase 2** — Core packages extracted; mac keeps orchestrators, stores, mesh, evolution engines
- [x] **Phase 3** — `Apps/NoxMac` home for app sources (adapters + UI remain mac-only by design)
- [x] **Phase 4** — App root at `Apps/NoxMac/Nox`; `project.pbxproj` paths updated
- [x] **Phase 5** — Removed `@_exported` `NoxPackageExports.swift`; explicit `import Nox*` per app/test file
- [x] **Phase 6** — Domain tests in `Packages/*/Tests/`; `NoxTests/Mac/` for app integration; stub `NoxTests.swift`
- [ ] **Phase 7 (decomposition)** — `NoxContextMemoryPipeline` done; observation/event pipelines + package fills — see `Docs/PLATFORM_DECOMPOSITION.md`
- [ ] **Phase 2b (incremental)** — Re-extract behavioral / ambient / system-state from mac when dependency graph is clean

## macOS-only inventory (representative)

| Area | Path under `Apps/NoxMac/Nox/` | Reason |
|------|-------------------------------|--------|
| SQLite stores | `Core/Persistence/*Store.swift` | SQLite3 |
| Activity | `Core/Activity/NoxActivityObserver.swift` | AppKit / AX |
| Presence mesh | `Core/PresenceMesh/` | Network, Bluetooth, HTTP |
| Memory evolution | `Core/MemoryEvolution/`, coordinators | Cross-domain orchestration |
| Continuity engines | `Core/Continuity/NoxContinuityEngine.swift`, maturity orchestrators | SQLite + memory coupling |
| Behavioral / ambient / system-state | `Core/BehavioralIntelligence/`, `Core/AmbientUtility/`, `Core/SystemState/` | Full pipelines; packages are placeholders |
| Observatory providers | `Core/Observatory/NoxObservatoryDataProvider*.swift` | App adapters |
| SwiftUI features | `Features/` | SwiftUI |

## Compile rules (shared packages)

Allowed: `Foundation`, limited `CoreGraphics` (e.g. spacing).

Forbidden: `AppKit`, `SwiftUI`, `NSWorkspace`, `ApplicationServices`, screen APIs, `EventKit`, `UserNotifications`, `IOKit`, `CoreBluetooth`, `Network`, `SQLite3`, menu-bar/window APIs.

## Rollback

- Small commits per phase; `git mv` for moves
- If extraction blocks, leave in `Apps/NoxMac/Nox/` with `// TODO(platform):` and reason
- Do not rewrite stores, mesh transport, or `NoxActivityObserver` during extraction-only work

## Blockers log

| File / area | Blocker | Stay in |
|-------------|---------|---------|
| `*Store.swift` | SQLite3 | NoxMac |
| `NoxActivityObserver` | AppKit / AX | NoxMac |
| `NoxObservatoryDataProvider` | Cross-package orchestration | NoxMac |
| `NoxObservatorySignals+Color` | SwiftUI `Color` | NoxMac / Features |
| Memory ↔ continuity orchestrators | Cycles if split naively | NoxMac |
| Behavioral / ambient / system-state pipelines | Not yet split | NoxMac (+ placeholder packages) |
