# Nox Resource Budget

Nox is an ambient macOS system layer. When the panel is closed it should feel almost invisible: observers may remain alive, but they must avoid unnecessary UI invalidation, animation work, noisy persistence, and unbounded memory growth.

Performance optimizations must preserve behavior first. A slower correct Nox is better than a fast broken Nox.

## Release Targets

| Mode | CPU target | Memory target |
| --- | ---: | ---: |
| Idle, panel closed | 0-1% | Ideally <=100 MB; hard warning above 120 MB |
| Passive monitoring, panel closed | 1-3% | <=120 MB |
| Panel open / active UI | Short spikes accepted; sustained >5% must be investigated | Sustained >150 MB must be explained |

## Spike Policy

Short CPU spikes are acceptable during app switches, permission refresh, discovery sweeps, memory reloads, restart recovery, maintenance, and panel open. A spike becomes a regression when it is sustained while the panel is closed, repeats without a user/system event, or causes visible lag.

## Debug vs Release

Debug builds are useful for correctness and log inspection, but they are not resource-budget evidence. Release builds are the reference for CPU and memory judgement because SwiftUI, Observation, package optimization, assertions, and logging all behave differently.

Debug-only diagnostics may be noisy. Release diagnostics must be passive, bounded, and quiet by default.

## Regression Definition

A performance change is a regression if it:

- Drops, delays, or silently suppresses meaningful timeline, activity, session, semantic, continuity, permission, system, or presence events.
- Changes public UX naming or product language.
- Weakens persistence, recovery, retention, deduplication, contradiction detection, or trust controls.
- Keeps duplicate timers/watchers alive after shutdown or repeated starts.
- Causes panel-closed UI work, animation work, or memory growth with no corresponding event.
- Increases sustained idle CPU above 1%, passive CPU above 3%, or panel-open CPU above 5% without explanation.
- Pushes idle memory above 120 MB or panel-open memory above 150 MB without explanation.

## Measurement

Use Release builds for budget decisions:

1. Build with `xcodebuild -project Nox.xcodeproj -scheme Nox -configuration Release build`.
2. Launch the Release app and let it settle for at least 60 seconds.
3. Measure idle, panel closed with Activity Monitor or Instruments Time Profiler.
4. Measure passive monitoring after normal app switching and window title changes.
5. Open the panel and verify spikes settle.
6. Inspect `NoxPerformanceDiagnosticsSnapshot` from a local debug hook or debugger to confirm active watchers, panel state, visual-effect state, buffer sizes, and timeline write behavior.
7. During a stable surface, semantic evaluation should follow `NoxSemanticEvaluationCadence`: immediate on app/window/document/idle transitions or forced durable engagement, otherwise cadence-gated.

## Must Never Be Optimized Away

- Activity observation, app switching, window/title/document context, idle transitions, sessions, semantic inference, continuity, memory evolution, system contradictions, restart recovery, retention maintenance, permissions, Presence Mesh trust/pairing, and user trust controls.
- Timeline persistence and memory persistence for meaningful events.
- Deduplication and throttling rules that preserve meaningful state transitions.
- Safety naming around Constellation/Galaxy/Orbit/Deep Space, Nox I, Station, Satellite, and Beacon.

## Current Audit Notes

| Suspected source | File/path | Risk | Safe fix | Regression risk |
| --- | --- | --- | --- | --- |
| Untracked background loops for permission and interaction sampling could survive repeated starts until process exit. | `Apps/NoxMac/Nox/App/NoxContextService.swift` | Medium | Store Task handles, cancel before restart and on stop. | Low; interval and emitted events are unchanged. |
| Startup maintenance and periodic maintenance were separate code paths. | `Apps/NoxMac/Nox/App/NoxContextService.swift` | Low | Keep both semantics but make each cancellable. | Low; 45s startup pass and long interval pass remain. |
| Activity observer polls every 1s, relaxes to 5s when surface is stable, and bursts at 250ms after app/window shifts. | `Apps/NoxMac/Nox/Core/Activity/NoxActivityObserver.swift` | Medium | Leave behavior intact; future optimization should prove AX/window-title equivalence before changing intervals. | Medium; app/window capture can regress if loosened. |
| Stable snapshots could repeatedly drive semantic inference and semantic memory writes. | `Apps/NoxMac/Nox/App/NoxContextService.swift`, `Apps/NoxMac/Nox/Core/Semantic/NoxSemanticEvaluationCadence.swift` | High | Evaluate immediately on meaningful transitions; cadence-gate unchanged stable snapshots. | Low with tests; transitions and forced durable engagement still evaluate. |
| Semantic heartbeat runs every 3s. | `Apps/NoxMac/Nox/App/NoxContextService.swift` | Medium | Keep heartbeat for label freshness, but route stable semantic work through cadence. | Low with heartbeat/cadence tests. |
| UI-facing derived state was reassigned even when arrays/values were unchanged. | `Apps/NoxMac/Nox/App/AppEnvironment.swift`, `Apps/NoxMac/Nox/App/NoxContextService.swift` | Medium | Add Equatable guards for live signals, capability rows, memory emergence, and semantic hint. | Low; values are identical, only redundant Observation invalidations are skipped. |
| Presence discovery refreshes every 60s only while Presence UI is active. | `Apps/NoxMac/Nox/Core/PresenceMesh/PresenceMeshManager.swift` | Low | Keep page lifecycle gate; diagnostics expose whether discovery is active. | Low. |
| Live signal and recent bundle buffers are bounded. | `Apps/NoxMac/Nox/Core/Live/NoxLiveSignalBuffer.swift`, `Apps/NoxMac/Nox/App/NoxContextService.swift` | Low | Keep caps and expose sizes in diagnostics. | Low. |
