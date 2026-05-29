# Platform decomposition (after migration)

Migration moved **domain** into `Packages/*` and **macOS adapters + UI** into `Apps/NoxMac/Nox`. Decomposition is the next step: smaller units that are easy to review, test, and reuse — similar in *intent* to a well-structured React repo, but enforced differently in Swift.

## React vs Swift — same idea, different enforcement

| Idea | Typical React monorepo | Nox (Swift) |
|------|------------------------|-------------|
| Shared library | `packages/ui`, `packages/api-client` | `Packages/NoxMemoryCore`, `NoxSemanticCore`, … |
| App shell | `apps/web/src/main.tsx` | `Apps/NoxMac/Nox/App/` |
| Feature UI | `apps/web/src/features/dashboard/` | `Apps/NoxMac/Nox/Features/Dashboard/` |
| Feature logic (pure) | `packages/domain/` or colocated hooks | `Packages/*` — **compiler boundary** |
| “Barrel” re-export | `index.ts` re-exports everything | Avoided — explicit `import NoxMemoryCore` per file |
| Boundary | Convention + lint | **SPM modules** + `public` / `internal` + import-boundary script |

In React you *can* import a dashboard component from a mesh file if the path alias allows it. In Swift, code in `NoxMemoryCore` **cannot** call SQLite or SwiftUI unless you add forbidden dependencies — the linker stops you.

So: **folder structure alone is not enough** in Swift; real decomposition is **packages (or extra Xcode targets)**, not only `Features/` directories.

## Recommended layers (current + next)

```
Packages/                    # Universal domain — swift test per package
  NoxPlatformContracts/
  NoxShrineCore/
  NoxCore/
  NoxContextCore/
  …

Apps/NoxMac/Nox/
  App/                       # Lifecycle, composition root (like app entry + providers)
  Core/                      # macOS-only: stores, observers, orchestrators
    Persistence/             # SQLite adapters
    PresenceMesh/            # Network / Bonjour / pairing transport
    MemoryEvolution/         # Cross-domain pipelines (stay until graph is clean)
  Features/                  # SwiftUI surfaces (like route-level feature folders)
    Dashboard/
    Observatory/
    …

NoxTests/
  Mac/                       # Integration tests (@testable import Nox) — one file per suite
  *.swift                    # Thin mac-only tests (rollup store, mesh invite, …)
```

### What belongs where

| Put in **Packages** | Put in **Apps/NoxMac** |
|---------------------|-------------------------|
| Models, enums, pure engines | `NoxActivityObserver`, windowing, menu bar |
| Deterministic inference / rollups (no I/O) | `*Store.swift`, `timeline.db` |
| Mesh **crypto**, message shapes, curator rules | HTTP/BT transport, keychain, invites |
| Copy / label catalogs (Foundation) | SwiftUI views, AppKit helpers |
| Shrine contracts, behavior packets, pure selection policy | Notch/Bubble panels, sound playback, fullscreen/video adapters |

## Decomposition phases (after migration green)

1. **File-level (done / in progress)**  
   - `NoxTests/Mac/*.swift` — one struct per file instead of a 3k-line `NoxTests.swift`.  
   - Package tests for pure domain (`NoxPresenceCoreTests`, `NoxMemoryCoreTests`, …).

2. **Feature folders (organizational)**  
   - Keep `Features/<Name>/` for UI only; no new business rules there — call into `Core/` orchestrators or package APIs.

3. **Module-level (strong boundary)**  
   - When a `Core/` subtree has no mac imports and stable deps → move to an existing or new `Nox*Core` package.  
   - Placeholder packages (`NoxBehavioralIntelligenceCore`, …) fill in incrementally — see `PLATFORM_MIGRATION.md` Phase 2b.

4. **Coordinator extraction (in progress)**  
   - `NoxContextMemoryPipeline` — dashboard reload + connector/behavioral/ambient/evolution orchestration (~450 lines extracted from `NoxContextService`).
   - Next candidates: `NoxContextObservationPipeline` (snapshots, semantics, presence), `NoxContextEventPipeline` (timeline/events).

5. **Optional Xcode targets (later)**  
   - e.g. `NoxMacUI` vs `NoxMacAdapters` — only if build times or coupling hurt; SPM packages are usually enough.

## Testing strategy

| Layer | Run with |
|-------|----------|
| Domain | `swift test --package-path Packages/<Name>` |
| macOS integration | `xcodebuild test -only-testing:NoxTests` |
| UI | `NoxUITests` (separate gate) |

Prefer adding tests next to the module they assert — not only in the app test bundle.

## Scripts

| Script | Purpose |
|--------|---------|
| `Scripts/fix-swift-imports.py` | Dedupe imports; `--add-nox-packages` for app sources |
| `Scripts/split-noxtests.py` | Split `NoxTests.swift` → `NoxTests/Mac/` |
| `Scripts/check-package-import-boundaries.sh` | Forbidden imports in packages |

## Anti-patterns

- `@_exported import` barrels in the app — hides dependencies; use explicit imports.
- Duplicating domain types in `Core/` and `Packages/` — one canonical type in the package.
- Huge `Core/BehavioralIntelligence/` without package extraction — OK temporarily; track in migration blockers.
- Putting AppKit/SwiftUI Shrine windows in `NoxShrineCore` — ShrineCore is contracts and pure policy only.
- Assuming Raspberry Pi can run the macOS app — Pi Shrine needs a separate Linux-safe runtime speaking shared contracts.

## Performance (separate from decomposition)

Decomposition does not replace observation economics. See `Docs/PERFORMANCE.md` for idle CPU/network tactics (snapshot coalescing, lazy mesh, gated memory reload).

## Related docs

- `Docs/PLATFORM_ARCHITECTURE.md` — capability matrix, layers  
- `Docs/PLATFORM_MIGRATION.md` — phase checklist, mac-only inventory  
- `Docs/PERFORMANCE.md` — resource targets and optimizations  
