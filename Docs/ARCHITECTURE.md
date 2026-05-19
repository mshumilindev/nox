# Nox Architecture

Last updated: 2026-05-19

## Product Intent

Nox is a local-first ambient memory layer for macOS. It observes local context over time, stores metadata and derived summaries instead of raw surveillance content, and surfaces calm continuity in the menu bar and floating panel.

Nox is not a chatbot, cloud assistant, productivity scorer, screenshot recorder, clipboard tracker, or keystroke logger.

## Current Stack

| Layer | Current choice |
| --- | --- |
| Language | Swift 5 |
| UI | SwiftUI surfaces with AppKit bridges |
| Lifecycle | SwiftUI `App` plus `NoxAppDelegate` |
| Menu bar | `NSStatusItem` through `NoxStatusBarController` |
| Dropdown | `NSPanel` hosting `NoxMenuBarView` |
| Floating dashboard | `NoxWindowController` + `NoxPanelState` |
| Runtime state | `@Observable` `AppEnvironment`, centralized in `NoxAppRuntime` |
| Persistence | Local SQLite stores under the app container |
| Platform | macOS 14+ |
| Sandboxing | App Sandbox enabled |
| Agent mode | `LSUIElement`, no Dock-first experience |

No third-party runtime dependencies are currently used.

## Runtime Flow

```
NoxApp
  -> NoxAppDelegate
  -> NoxAppRuntime
  -> NoxStatusBarController
  -> AppEnvironment
  -> NoxContextService
```

`NoxContextService` is the runtime coordinator. On startup it opens local stores, hydrates persisted state, starts local observation, samples interaction aggregates, runs semantic heartbeat evaluation, refreshes memory views, and schedules memory maintenance.

## Observation Pipeline

```
NoxActivityObserver
  -> NoxEventBus
  -> NoxContextService
  -> timeline / memory / semantic / presence pipelines
  -> AppEnvironment
  -> SwiftUI surfaces
```

- `NoxActivityObserver` uses `NSWorkspace` notifications, idle polling, AX focus monitoring when available, wake/sleep notifications, and screen lock notifications.
- `NoxWindowContextReader` reads focused window title and browser document URL only when permissions allow.
- `NoxInteractionSignalCollector` samples timing aggregates from system input state: typing activity, scroll activity, pointer activity, active/idle interaction windows, and burst density. It does not read typed content.
- `NoxSelfExclusion` prevents Nox from entering its own behavioral memory.

## Permissions

| Permission | Purpose |
| --- | --- |
| Accessibility | Focused window title, browser URL via AX document, focused UI role hints |
| Screen Recording | Optional window-title fallback via window metadata |
| Calendar | Optional read-only EventKit timing profile for generalized coordination context |

Calendar support is implemented in code and guarded by user preference and EventKit authorization. Because the app is sandboxed, release validation should confirm the final entitlement profile for calendar access before describing it as production-ready.

## Context And Semantics

The context layer is deterministic and local:

- `NoxContextAcquisitionPipeline` builds evidence from app identity, window metadata, document URL, permissions, interaction aggregates, stable duration, recent switching, and adapters.
- Adapters cover browser-like, editor-like, terminal-like, communication-like, creative-like, media-like, game, file transfer, generic app, and unknown fallback contexts.
- `NoxSemanticInferenceEngine` classifies local context into human-facing semantic states such as development, research, travel planning, AI-assisted work, passive media, writing, fragmented workflow, and sensitive/private contexts.
- `NoxSemanticLiveSignalPresenter` gates semantic pulses with cooldowns and deduplication.
- `NoxContextDebugSnapshot` exposes reasoning in Debug builds only.

## Memory Architecture

```
timeline_events
  -> NoxMemoryAggregator
  -> activity_spans + interruptions
  -> NoxFocusInterruptionEngine
  -> focus_blocks
  -> NoxSemanticMemoryEngine
  -> semantic_spans
  -> NoxContinuityEngine
  -> continuity_threads
  -> NoxMemoryMaintenanceCoordinator
  -> rollups + typed memories + reflections
```

Memory is layered:

- Hot: in-memory signals and current inference state.
- Warm: recent timeline events and activity spans, pruned by retention policy.
- Cold: semantic spans, sessions, continuity threads, rollups, typed memories, and reflections.

The visible memory timeline is layered by continuity, semantic memory, focus, activity, and interruptions. Raw activity spans are deduped when they are already covered by semantic spans.

## Long-Horizon And Reflection

The reflective continuity layer is deterministic:

- `NoxMorningContinuityEngine` creates calm morning or return summaries when cooldown and timing rules allow.
- `NoxEmergingMemoryEngine` describes early memory maturity before durable patterns exist.
- `NoxSemanticArcEngine` groups semantic spans into evolving arcs.
- `NoxReflectiveSynthesisEngine` creates low-frequency reflection candidates from deterministic memory inputs.
- `NoxReflectionStore` persists reflection candidates locally.
- `NoxLongHorizonLoader` assembles threads, arcs, rhythms, era candidates, rollup narratives, resurfacing notes, connector notes, and reflections for long-horizon surfaces.

There is no integrated LLM pass, assistant chat surface, or cloud reflection service.

## Connector-Aware Continuity

Phase 9 adds connector-aware ambient continuity without turning connectors into primary memory:

- Calendar context uses EventKit timing and generalized day shape only. Event titles are not persisted.
- Communication pressure is inferred from local activity spans and app cadence, not inbox contents.
- Cadence detects work/recovery oscillation and coordination rhythms.
- Transitions detect deep-work entry/exit, fragmentation, return-after-absence, and passive-media shifts.
- Recovery signals describe overload-like conditions observationally, not as health scoring.
- Interventions are rare, cooldown-protected, and non-demanding.
- Trust controls expose connector toggles, enrichment pause, and local clearing of connector-derived continuity.

## Persistence

Local SQLite stores include:

- timeline events
- activity spans and interruptions
- focus blocks
- semantic spans
- sessions
- continuity threads
- ambient state
- preferences
- rollups
- typed memory entities
- reflections
- connector cadence patterns

No cloud sync, encrypted export, or backup workflow exists yet.

## Privacy Baseline

Nox must not persist:

- screenshots or screen replay
- clipboard history
- typed text or keystroke content
- raw browser page contents
- full email/message bodies
- passwords or authentication contents

Sensitive contexts are generalized before display or storage, and product copy should describe local signals without surveillance language.

## Testing Strategy

Tests focus on deterministic logic outside SwiftUI:

- presence and stabilization
- permission/capability matrices
- context scenario QA
- classification and semantic inference
- sensitive-context redaction
- live signal deduplication
- memory aggregation, search, retention, compression
- semantic spans, continuity, resurfacing
- reflective continuity
- connector Phase 9 logic
- persistence round trips

UI tests exist, but the product strategy intentionally avoids brittle layout tests as the main validation path.

## Known Architecture Risks

- Calendar access should be validated against the final sandbox entitlement setup.
- Long-horizon surfaces may need density tuning as real memory grows.
- Native Mail/Slack metadata connectors are not implemented; current communication pressure uses local activity proxies.
- Optional encrypted export/backup is not implemented.
- Optional on-device reflection enhancement is not implemented.
