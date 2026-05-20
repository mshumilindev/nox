# Performance and resource use

Baseline (menu-bar idle, Xcode debug, typical Mac): ~10–15% CPU, ~80–90 MB RAM, **Low** energy, disk spikes when memory view reloads, network near zero unless Presence mesh is active.

**Structural decomposition** (packages, file splits) improves maintainability; it does **not** by itself deliver 10× lower CPU/RAM. That target needs **observation economics** — less work per idle second, same product behavior.

## Honest target: 10× without losing 1% functionality

| Resource | Realistic without feature cuts | How |
|----------|-------------------------------|-----|
| CPU (idle) | **2–4×** | Skip redundant snapshot pipeline; defer mesh browsers |
| Network (idle) | **5–10×** | Lazy mesh + Nox-only Bonjour until Presence opens |
| Disk | **2–5×** | Avoid `reloadMemoryView` when dashboard closed; skip focus-block rewrite when unchanged (future) |
| RAM (~88 MB) | **~1.1–1.3×** | SwiftUI + SQLite + caches; big wins need fewer in-memory orchestration snapshots |

True **10× on all axes** while keeping always-on observation, full memory, connectors, and mesh pairing is not credible without product tradeoffs (e.g. pause observation when idle, smaller retention, or on-demand mesh only).

## Implemented (2026-05-20)

1. **Snapshot coalescing** — `NoxActivitySnapshot.hasSameObservationSurface`; observer and `ingestSnapshot` skip semantic/memory/orchestrator work when app/title/idle bucket unchanged (`NoxCore`, `NoxActivityObserver`, `NoxContextService`).
2. **Nox mesh at launch** — `_nox._tcp` publish/browse + HTTP transport start on app launch (required for peer discovery). `ensureStarted()` remains for invite/deep-link edge cases.
3. **Apple ecosystem diet at idle** — AirPlay/HomeKit Bonjour browsers and Continuity BLE only while the Presence page is open (`BonjourPresenceDiscoveryProvider`, `CompositePresenceDiscoveryProvider`).
4. **Memory UI reload gate** — `scheduleMemoryReload()` no-op when dashboard closed; full reload on `prepareForDashboard()` (`NoxContextService`, `AppEnvironment`).
5. **Adaptive activity poll** — 1 s when context changes; 5 s when observation surface is stable (`NoxActivityObserver`).
6. **Focus block write skip** — skip SQLite clear/insert when span/interruption/focus fingerprint unchanged (`NoxMemoryCoordinator`).

## Next high-impact (no behavior change)

| Item | Est. win | Risk |
|------|----------|------|
| ~~Adaptive poll~~ | CPU | Done — 5 s relaxed cadence |
| ~~Skip focus-block SQLite rewrite~~ | Disk | Done — fingerprint cache |
| Split `NoxContextService` into coordinator types | Maintainability | Requires `internal` APIs or new types |
| Tiered `reloadMemoryView` (cheap stats vs full orchestrators) | CPU spikes | Refactor size |
| Trim 12 package imports on hot files | Build time | Low runtime |
| Instruments Time Profiler + Energy Log | Measurement | — |

## How to verify

1. Xcode → Debug Navigator: CPU, Memory, Energy, Disk, Network (compare before/after at menu-bar idle 2 min).
2. `xcodebuild test -only-testing:NoxTests` and `swift test` on `NoxCore`, `NoxPresenceCore`.
3. Manual: open Presence (mesh should start), pair/import invite, dashboard memory still updates when opened.

## Related

- `Docs/PLATFORM_DECOMPOSITION.md` — module boundaries  
- `Docs/PLATFORM_MIGRATION.md` — extraction status  
