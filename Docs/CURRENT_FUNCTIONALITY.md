# Nox Current Functionality

Last updated: 2026-05-19

This document is the living inventory of what Nox actually implements today. Update it after every development phase so planning reflects shipped behavior, not intent.

## Product State

Nox is currently a native macOS menu bar app with a floating dashboard, local activity awareness, deterministic context inference, structured memory, continuity detection, reflective continuity surfaces, and local persistence.

It is not a chatbot, cloud assistant, productivity scorer, screenshot recorder, clipboard tracker, or keystroke logger.

## App Shell

- Native SwiftUI macOS app with `MenuBarExtra`.
- Agent-style app using `LSUIElement`; it lives in the menu bar without a Dock-first experience.
- Floating dashboard is owned by `NoxWindowController` through `NoxPanelState`, with single-window open/focus behavior.
- Runtime singletons are centralized in `NoxAppRuntime`.
- `AppEnvironment` owns UI-facing state for presence, permissions, live signals, timeline blocks, semantic context, search, memory period, long-horizon memory, morning continuity, reflections, memory maturity, and active app context.
- App lifecycle can checkpoint memory and session state before termination through `NoxLifecycleCoordinator` and `NoxContextService`.

## Menu Bar Experience

- Menu bar icon reflects presence through `NoxMenuBarIcon`.
- Dropdown shows:
  - current presence;
  - live context pulse;
  - semantic hint when available;
  - compact live signal feed;
  - actions for opening Nox and quitting;
  - calm local-first philosophy copy.
- Menu bar copy avoids surveillance language.

## Floating Dashboard

- Dashboard contains:
  - header and presence panel;
  - live signals;
  - **long-horizon memory surface** (continuity, arcs, reflections, rhythms);
  - morning continuity banner when triggered;
  - memory period picker;
  - memory search;
  - structured memory timeline;
  - system/capability status;
  - debug context explainability in debug builds;
  - philosophy footer.
- Dashboard density reacts to memory richness.
- Timeline UI presents memory blocks, not a raw event stream.

## Reflective Continuity Layer (Phase 7)

### Morning Continuity Engine

- `NoxMorningContinuityEngine` generates calm continuity summaries on app launch, new day, long idle return, and morning window.
- `NoxMorningSummaryPresenter` shapes headline + supporting lines.
- Summaries are deterministic, non-coaching, and stored in ambient state cooldown (`lastMorningSummaryAt`).

### Long-Horizon Memory Surface

- `NoxLongHorizonView` surfaces:
  - active continuity threads;
  - emerging patterns;
  - semantic arcs;
  - reflective synthesis candidates;
  - behavioral rhythms and era candidates from typed memory;
  - weekly/monthly rollup narratives;
  - rare resurfacing notes (cooldown-protected).
- Card components: `NoxContinuityThreadCard`, `NoxSemanticArcCard`, `NoxBehavioralRhythmCard`, `NoxEraSurface`.

### Reflective Synthesis

- Pipeline: deterministic memory → `NoxReflectionInputBuilder` → `NoxReflectiveSynthesisEngine` → `NoxReflectionStore`.
- Low-frequency, cooldown-based (6h), confidence-gated.
- No chat UI, no streaming assistant.

### Emerging Memory States

- `NoxMemoryMaturity`: transient → emerging → stable → durable.
- `NoxEmergingMemoryEngine` produces calm copy when durable memory is not yet stable (e.g. repeated development activity, emerging threads).
- Timeline empty states use emerging observations instead of generic “Contexts are forming” when possible.

### Semantic Arcs

- `NoxSemanticArcEngine` groups spans into evolving arcs (development, research, travel, AI workflow, etc.).
- Arcs track continuity state (active, merging, fading, dormant, resurfaced) and evolution (strengthening, stable, fragmenting, decaying).

### Continuity Resurfacing UX

- Live resurfacing via `NoxContinuityEngine` + live signals (existing).
- Additional calm resurfacing lines via `NoxContinuityResurfacingOrchestrator` on the long-horizon surface (15 min cooldown).

### Memory Stability

- Semantic span minimum duration reduced (32s) for faster stabilization.
- Memory span confidence threshold slightly lowered for MVP (`0.38`).
- Open spans exposed as transient memory via `currentOpenSpan`.

## Local Observation

- `NoxActivityObserver` observes:
  - frontmost app changes;
  - window title changes where permissions allow;
  - idle state;
  - wake/sleep/screen lock style system events;
  - periodic activity snapshots.
- `NoxWindowContextReader` and Accessibility support richer window context when available.
- Observation runs locally and is not UI-driven.
- Nox excludes its own activity from behavioral memory through `NoxSelfExclusion`.

## Permissions And Capabilities

- `NoxPermissionService` checks Accessibility and Screen Recording availability.
- `NoxCapabilityMatrix` translates permission state into user-visible capability rows.
- Runtime supports awareness tiers:
  - unavailable;
  - app-level awareness;
  - full awareness.
- Permission changes emit events and update live signals.
- UI exposes paths to Accessibility and Screen Recording settings.

## Event Pipeline

- `NoxEventBus` routes typed `NoxEvent` values.
- Events include app changes, window changes, idle transitions, permission changes, presence changes, session transitions, and interaction aggregates.
- Warm timeline persistence stores events in SQLite through `NoxTimelineStore`.
- Duplicate app-change events are suppressed within a short window.
- Forbidden memory content rules prevent certain event types from entering the warm timeline.

## Presence

- `NoxPresenceEngine` derives presence locally from capability state, idle state, current app, time in app, recent switching, live signals, and focus analysis.
- `NoxPresenceStabilizer` prevents twitchy state changes.
- Presence supports calm states such as quiet, active, focused, flow, idle, limited, and unavailable.
- Presence changes are persisted as timeline events.

## Sessions

- `NoxSessionDetector` detects rule-based work sessions from productive app focus and activity continuity.
- Current session summary is surfaced in menu bar and dashboard.
- Active and ended sessions are persisted through `NoxSessionStore`.
- Restart recovery can resume or close interrupted sessions.

## Interaction Semantics

- `NoxInteractionSignalCollector` samples interaction aggregates.
- Stored semantics use typing density, scroll intensity, mouse density, active/idle interaction windows, and burst counts.
- Nox does not store typed text or keystroke content.
- `NoxInteractionMetricsAggregator` resets on context shifts and supports passive playback mode.

## Context Acquisition

- `NoxContextAcquisitionPipeline` builds explainable context evidence from activity snapshots.
- Context adapters exist for browser-like, editor-like, terminal-like, communication-like, creative-like, media-like, game, file transfer, generic app, and unknown fallback contexts.
- `NoxContextDebugSnapshot` can expose reasoning in debug builds.

## Semantic Inference

- `NoxSemanticInferenceEngine` performs deterministic local semantic inference.
- `NoxSemanticLiveSignalPresenter` applies cooldowns and deduplication before showing semantic pulses.
- Browser context classification can identify categories such as development, research, AI tools, travel, and passive media.

## Privacy And Sensitive Contexts

- `NoxSensitiveContextHandler` classifies sensitive and private contexts.
- Sensitive/private contexts are generalized before storage or display.
- Semantic memory for sensitive contexts stores generic continuity rather than detailed labels.
- No cloud, screenshots, clipboard capture, raw browser contents, or long-term typed text storage are implemented.

## Structured Memory

- `NoxMemoryCoordinator` coordinates memory ingestion, querying, semantic spans, continuity, rollups, typed memories, reflections, and maintenance.
- Activity memory includes spans, interruptions, focus blocks, semantic spans, continuity threads, compressed rollups, and typed memory entities.
- `NoxDaySemanticFraming` creates a calm overview of today.
- `NoxReflectiveContinuityAssembler` bundles long-horizon, morning, emerging, and reflection outputs for the dashboard.

## Semantic Memory And Continuity

- `NoxSemanticMemoryEngine` opens, continues, closes, and persists semantic memory spans.
- `NoxSemanticSpanStitcher` merges compatible nearby spans.
- `NoxContinuityEngine` observes closed semantic spans and can resurface related continuity.
- Continuity decay runs during memory view loading.

## Memory Compression

- `NoxMemoryMaintenanceCoordinator` runs periodic maintenance.
- Deterministic rollups: hourly → daily → weekly → monthly → quarterly → yearly → era.
- `NoxLayerNarrativeBuilder` creates local deterministic narrative summaries from rollup facts.
- `NoxEraDetector` can detect era candidates from monthly rollups.

## Typed Memory

- `NoxTypedMemoryExtractor` derives typed long-horizon entities from compressed rollups.
- Kinds include AI workflow, travel planning, project arc, behavioral rhythm.
- Surfaced on the long-horizon memory layer.

## Persistence

- Local SQLite stores: timeline, spans, semantic spans, sessions, ambient state, rollups, typed memories, **reflections**.
- `NoxAmbientState` tracks restart continuity, morning summary timing, and resurfacing cooldowns.

## Testing

- Unit tests cover presence, memory, continuity, context QA, and **reflective continuity** (morning copy, emerging memory, arcs, reflection cooldown).
- UI test files exist; product strategy avoids brittle layout UI tests as primary validation.

## Current Gaps And Risks

- Reflection synthesis is deterministic only; optional LLM pass is not integrated.
- Long-horizon surface may need visual density tuning as memory grows.
- No external connector layer (calendar, mail, Jira, browser APIs beyond local inference).
- No cloud sync, encrypted export, or backup workflow.
- Permission onboarding may still need product polish.

## Best Next-Step Candidates

- Optional on-device reflective synthesis pass (still non-chat).
- Connector intake as secondary signals.
- Stronger permission/onboarding for awareness tiers.
- Visual polish for semantic arc topology.
