# Nox Current Functionality

Last updated: 2026-05-20

This document is the living inventory of what Nox actually implements today. Update it after every development phase so planning reflects shipped behavior, not intent.

## Product State

Nox is currently a native macOS menu bar app with an adaptive ambient shell, local activity awareness, trust surfaces, memory controls, deterministic context inference, structured memory, continuity detection, reflective continuity, and local persistence.

It is not a chatbot, cloud assistant, productivity scorer, screenshot recorder, clipboard tracker, or keystroke logger.

## App Shell

- Native SwiftUI macOS app with an AppKit-backed `NSStatusItem` menu bar item.
- Agent-style app using `LSUIElement`; it lives in the menu bar without a Dock-first experience.
- Floating dashboard is owned by `NoxWindowController` through `NoxPanelState`, with single-window open/focus behavior.
- Runtime singletons are centralized in `NoxAppRuntime`.
- `AppEnvironment` owns UI-facing state for presence, permissions, preferences, awareness snapshots, explainability, live signals, **layered timeline sections** (`timelineSections`), semantic context, search, memory period, long-horizon memory (`longHorizonSnapshot`), **memory evolution** (`memoryEvolutionSnapshot`), morning continuity, reflections, memory maturity, **connector / behavioral / ambient utility snapshots**, and active app context.
- App lifecycle can checkpoint memory and session state before termination through `NoxLifecycleCoordinator` and `NoxContextService`.

## Menu Bar Experience

- Menu bar entry is an **`NSStatusItem`** via `NoxStatusBarController` (not `MenuBarExtra`), with `autosaveName` so the icon stays in the primary menu bar when possible.
- Tray icon: template asset **`NoxTrayTemplate`** (triskelion spiral) through `NoxMenuBarIcon.makeTemplateImage()` — adapts to light/dark menu bar automatically.
- Click opens a floating **`NSPanel`** dropdown (`NoxMenuBarView`, ~320×420) with the same atmospheric stack as the dashboard (scaled down).
- Dropdown shows:
  - wordmark header (`NoxMenuBarHeaderView` + `NoxTriskelionMark`);
  - current presence (`NoxPresenceBadgeView`);
  - compact live signals when available;
  - semantic hint when not duplicated in the pulse;
  - actions to open the dashboard and quit;
  - calm philosophy copy (`NoxPhilosophySurface`).
- Menu bar copy avoids surveillance language.

## Visual Identity (Phase 8.5–8.7)

### Phase 8.7 — Human UI pass
- **Three surface levels:** `major` (rare hero), `standard` (entities), `soft` (metadata/controls) — replaces uniform mega-cards.
- **`noxGroup`** replaces heavy `noxCluster` wrappers; readable width cap (~520pt) on surfaces.
- **Memory timeline:** layered sections (`NoxTimelineSectionView` / `NoxTimelineRowView`), fixed row heights, SF Symbol markers aligned to title line (no dot/circle chrome).
- **Trust:** single composed boundaries list; calmer memory controls (toggle alignment, menu picker, quiet links).
- **Now:** flat vertical composition — one `standard` presence block, `soft` live context, `major` morning only.
- **Sidebar:** left-aligned rows, semantic grouping, accent bar selection (not icon-column template).
- **Mode control:** underline selection, no glossy segmented pill.
- **Interaction:** `NoxAmbientHover` on buttons/chips only; `noxInteractiveChrome` on toggles/pickers (hover only — no custom pointer cursor).

## Design System & Atmosphere (Phase 8.5–8.7 + brand pass)

### Semantic colors (asset catalog, light/dark)

- UI colors come from **`Assets.xcassets`** color sets (`NoxCanvas`, `NoxSurface`, `NoxRail`, `NoxAccent`, `NoxTextPrimary`, `NoxTextSecondary`, `NoxBorder`, reflection/trust/presence roles, etc.) — each defines **universal + dark** appearances where needed.
- `NoxDesignTokens.ColorRole` resolves these at runtime; the shell follows **system `colorScheme`** (light day / dark night), not a forced dark-only theme.

### Brand assets

- **Triskelion mark:** `NoxTriskelionMark` (navigation rail, menu bar header); variants `NoxTriskelionSoft`, `NoxTriskelionEmbossed` in catalog.
- **Menu bar tray:** `NoxTrayTemplate` (template PDF/SVG).
- **App icon:** `AppIcon.appiconset` with generated `NoxAppIcon-*` PNG sizes.
- **Night atmosphere image:** `NoxNightAuroraBackground` — static raster aurora plate (source notes in `Assets/Source/RAWPIXEL_AURORA_SOURCE.md`).
- **Notification glyph:** `NoxNotificationGlyph` (triskelion).
- Design sources tracked under `Assets/Source/` (triskelion SVG + attribution markdown).

### `NoxAtmosphereBackground` (static, no procedural animation)

Procedural Canvas aurora was **removed**. Current stack:

1. **Base Canvas** — day: cool graphite gradient + radial depth; night: dark vertical gradient + subtle radial haze + sparse static stars (window only).
2. **Night image layer** (evening / night / deepReflection when asset loads) — `Image("NoxNightAuroraBackground")`, `scaledToFill`, toned down (saturation/contrast/brightness), dark gradient overlay; opacity ~0.34 window / ~0.46 deep reflection / ~0.32 menu bar.
3. **Optical Canvas** — top vignette + soft border stroke.

`NoxAtmosphericState`: `day`, `evening`, `night`, `deepReflection` — **`isAnimated` is always false** today.

**Shell mapping** (`NoxAmbientShellView`): `colorScheme == .light` → `.day`; dark + normal mode → `.night`; dark + **Deep reflection** window mode → `.deepReflection`. The `.evening` enum case exists for the image layer but is **not** selected by the shell (hour-of-day scheduling was removed).

### Layout & components (unchanged intent)

- **Spacing scale (4pt base):** 4 · 8 · 12 · 16 · 24 · 32 · 48 — `NoxSpacing`, `NoxSurfacePage`, consistent card insets.
- **Typography:** `noxSectionLabel`, `noxMetadata`, `NoxPageIntro` / `NoxSectionHeader`, `NoxTypography.wordmark` / `tagline`.
- **Icons:** `NoxIcon` + `NoxSFSymbol.validated`; rail uses template triskelion, not generic app symbol.
- **`NoxMaterials`** — tiered surfaces (`major` / `standard` / `soft`), borders, rail width **128pt**.
- **`NoxWindowModeControl`** — underline mode switch; fixed sizes in `NoxDesignTokens.Window` (Compact 368×460, Expanded 560×660, Deep 720×820).
- **`NoxTitlebarLayout`** — shell chrome vertical padding / min height for traffic-light alignment.
- **Deep mode** swaps Patterns → `NoxDeepPatternsSurfaceView`, Reflections → `NoxDeepReflectionSurfaceView`.
- Content well opacity varies by atmosphere state (`contentAtmosphereOpacity` 0.18–0.42).

## Adaptive Ambient Shell (Phase 8)

- `NoxAmbientShellView` replaces the single scroll wall with semantic navigation:
  - **Now** — presence, awareness, live signals, explainability;
  - **Threads** — continuity threads with “why” cards;
  - **Memory** — timeline and search;
  - **Patterns** — arcs, emerging patterns, rhythms;
  - **Reflections** — calm reflection cards;
  - **Local** — local-first transparency and capability ladder;
  - **Trust** — privacy boundaries and memory controls.
- **Window modes:** Compact, Expanded, Deep reflection — fixed content sizes per mode; `NoxWindowController` opens a floating `NSPanel`-style window, syncs frame on mode change, default top-trailing placement until user moves it.
- **Appearance:** follows system light/dark (`colorScheme`); not locked to dark mode.
- **Progressive disclosure:** `NoxCollapsibleSection` folds dense content by default.
- **Trust center:** stored/never collected/sensitive/retention/reflection boundaries.
- **Memory controls:** pause observation, pause semantic memory, quiet modes, clear recent continuity.
- **Permission onboarding:** first-launch sheet explaining awareness tiers.
- **Emotional safety:** `NoxEmotionalSafetyCopy` blocks manipulative phrasing in product copy paths.

## Trust & Awareness

- `NoxAwarenessPresenter` — four human-facing awareness levels with scope labels.
- `NoxSemanticVisibilityMode` — how sensitive contexts are stored/displayed.
- `NoxExplainabilityPresenter` — “Why you're seeing this” without raw scores.
- `NoxQuietModeEngine` — quiet evening, private session, low awareness, pause continuity.
- Preferences persist via `NoxPreferencesStore` (local SQLite).

## Reflective Continuity Layer (Phase 7)

### Morning Continuity Engine

- `NoxMorningContinuityEngine` generates calm continuity summaries on app launch, new day, long idle return, and morning window.
- `NoxMorningSummaryPresenter` shapes headline + supporting lines.
- Summaries are deterministic, non-coaching, and stored in ambient state cooldown (`lastMorningSummaryAt`).

### Long-Horizon Memory (distributed surfaces)

`NoxLongHorizonLoader` + `NoxReflectiveContinuityAssembler` produce `NoxLongHorizonSnapshot` on every memory reload. **`NoxLongHorizonView` exists in code but is not mounted in the app** — content is split across semantic destinations:

| Destination | Long-horizon content |
| --- | --- |
| **Threads** | Active continuity threads + explainability cards (`NoxContinuityThreadCard` + evolution-aware copy) |
| **Memory** | Layered timeline + era observation line (`NoxMemoryTimelineView`, `NoxTemporalMemoryRowPresenter`) |
| **Patterns** | Emerging patterns, semantic arcs, continuity shapes, life-shaped periods, rhythms, cadence, connector enrichment, **temporal continuity** (Phase 12), era observation |
| **Reflections** | `NoxReflectionCandidate` cards from synthesis pipeline |
| **Now** | Morning summary, resurfacing notes, connector/utility interventions when gated |
| **Deep → Patterns / Reflections** | Deeper layout variants of Patterns and Reflections |

Shared card components: `NoxContinuityThreadCard`, `NoxSemanticArcCard`, `NoxBehavioralRhythmCard`, `NoxEraSurface` (optional `eraHints` from memory evolution).

Weekly/monthly rollup narratives and rare resurfacing notes are assembled into the snapshot; resurfacing respects cooldowns in `NoxAmbientState`.

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

### Memory timeline (layered + deduped + evolution UX)

- `NoxTimelineBlockPresenter.makeSections()` builds **five layers**:
  - Continuity → Semantic memory → Focus → Activity → Interruptions.
- Within each layer, items sort **newest-first** at presentation time; empty layers are hidden.
- After Phase 12 refresh, **`NoxTemporalMemoryRowPresenter.enrich`** applies aging copy and visual emphasis **once per reload** (no intermediate raw-then-enriched flash). Layer **order is preserved** (no weight-based re-sort inside layers — avoids flicker in Last 7 days).
- UI components: **`NoxTimelineSectionView`**, **`NoxTimelineRowView`** (opacity / temporal stamp / relation line), optional **`NoxMemoryEraObservationView`** above the timeline.
- **`NoxTimelineActivityDeduper`** drops raw activity spans when their **time interval** overlaps a semantic span (`NoxTimeInterval`: ≥30s overlap, ≥50% of shorter interval, or fully contained).
- **`NoxMemorySearchScope`** — when Filter memory is active, all layers narrow to search hits and shared time windows.
- **Historical periods** (Yesterday, Last 7 days) use static empty copy; temporal copy is **period-aware** (no “today” phrasing on 7-day view).
- **Emergence for Today only** — `periodScopedEmergence` uses `openSpan` and live signals only when `memoryPeriod == .today`.
- **Long-term resurfacing row** injected at top of Continuity layer on **Today only**, when evolution notes + resurfacing band align.
- **Timeline markers** — `NoxTimelineSymbol` + category `symbolName`; supports `.resurfacingMemory` kind for rare resurfacing rows.

### Activity classification (no “Unknown” in UI)

- `NoxAppClassifier` maps bundle IDs and title heuristics (including AI tools: ChatGPT, Codex, Claude, Perplexity, …) to `NoxActivityCategory`.
- Legacy DB rows with `category = unknown` are reclassified on read via `NoxActivityCategory.resolving` and repaired on store open (`repairLegacyUnknownCategories`).
- UI shows meaningful category titles (`Research`, `Development`, …) — not raw `Unknown`; thin fallback is `general` / `Active use`.

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

- Local SQLite stores: timeline, spans, semantic spans, sessions, ambient state, rollups, typed memories, **reflections**, **connector cadence patterns**.
- `NoxAmbientState` tracks restart continuity, morning summary timing, resurfacing cooldowns, and connector intervention cooldowns.

## Phase 9 — Connector-aware ambient continuity

- **Calendar context** (`NoxCalendarContextProvider`, classifier, pressure analyzer): read-only EventKit timing; generalized states only (no title persistence).
- **Communication pressure** (`NoxCommunicationPressureEngine`, cadence model): metadata from local activity spans — not inbox AI.
- **Cadence** (`NoxCadenceEngine`, `NoxRhythmDetector`): work/recovery oscillation, coordination rhythms, instability — not health scoring.
- **Transitions** (`NoxTransitionEngine`): deep work entry/exit, fragmentation, return-after-absence, passive-media shifts.
- **Recovery signals** (`NoxRecoveryInferenceEngine`): calm overload inference with observational copy.
- **Orchestration** (`NoxConnectorContinuityOrchestrator`): confidence-gated snapshot wired into reflective continuity and long-horizon enrichment.
- **Interventions** (`NoxAmbientInterventionEngine`): rare, 6-hour cooldown, non-demanding banners on Now.
- **Trust** (`NoxConnectorTrustControls`): per-connector toggles, enrichment pause, clear connector-derived continuity.
- **Explainability** (`NoxConnectorExplainability`): provenance for what was and was not collected.
- **UI**: sparse cadence/pressure cards on Now; cadence enrichment on Patterns; connector rows in Trust.

## Phase 10 — Emergent behavioral intelligence

Local-first, deterministic, confidence-gated layer in `Nox/Core/BehavioralIntelligence/`:

- **Pattern engine** (`NoxBehavioralPatternEngine`, `NoxBehavioralSignature`, `NoxPatternConfidenceModel`): recurring structures (late-night work, overload–recovery oscillation, coordination-heavy stretches, deep-focus streaks, fragmentation, creative exploration, passive decompression, instability) — probabilistic and explainable, not personality typing.
- **Contextual expectations** (`NoxContextualExpectationEngine`, `NoxExpectedRhythmModel`): likely work/recovery windows and transition hints for timing sensitivity only.
- **Adaptive continuity** (`NoxAdaptiveContinuityModel`): dynamic thread weights from recurrence, resumptions, pattern alignment, and arc context.
- **Temporal rhythm** (`NoxTemporalRhythmEngine`): weekly/monthly/seasonal-like behavioral topology (not health AI).
- **Emergent life structures** (`NoxEmergentStructureEngine`, `NoxLifeStructureCandidate`): soft, revisable era labels (e.g. coordination-heavy period).
- **Drift** (`NoxBehavioralDriftEngine`): calm observational copy when rhythms diverge — never alarmist.
- **Adaptive interventions** (`NoxAdaptiveInterventionTimingEngine`): wraps Phase 9 interventions with orchestration-aware suppress/amplify and 6h cooldown.
- **Memory prioritization** (`NoxContextualMemoryPrioritizer`): orders threads/arcs and enrichment notes for long-horizon and resurfacing.
- **Orchestration substrate** (`NoxOrchestrationSignalLayer`, `NoxAmbientOrchestrationContext`): internal signals only (interruption sensitivity, focus stability, overload risk, recovery window, low fragmentation, return-after-absence) — not user-facing scores.
- **Orchestrator** (`NoxBehavioralIntelligenceOrchestrator`) + **persistence** (`NoxBehavioralIntelligenceSignalStore`): runs after connector refresh in `NoxContextService.reloadMemoryView()`; honors `continuityEnrichmentPaused`; clears with connector-derived data.
- **Integration**: `AppEnvironment.behavioralSnapshot`; reflective input/synthesis enriched with patterns and drift; `NoxLongHorizonLoader` reorders threads/arcs; Patterns surface shows sparse “Continuity shapes” and “Life-shaped periods” sections.

## Phase 10.5 — Continuity maturity pass

Refinement layer in `Nox/Core/ContinuityMaturity/` (no new product surfaces):

- **Reflection naturalization** (`NoxReflectionNaturalizationEngine`, `NoxReflectiveLanguageSoftener`, `NoxContinuityPhraseAssembler`, `NoxTemporalGroundingEngine`): softer continuity-native copy, temporal grounding (“recently”, “this week”), less taxonomy/engine vocabulary.
- **Continuity gravity** (`NoxContinuityGravityEngine`, `NoxContinuityImportanceModel`): recurrence, resurfacing, and persistence weight which reflections dominate vs fade.
- **Salience** (`NoxContinuitySalienceModel`): phrasing asymmetry (returning, unresolved, fragile, quiet) without emotion labels.
- **Suppression** (`NoxReflectionSuppressionEngine`): fewer reflections (2–3), marginal-confidence and near-duplicate filtering, long-horizon significance gate.
- **Contextual relevance** (`NoxContextualRelevanceFilter`): suppress mismatched observations (e.g. deep-focus copy during fragmentation unless high gravity).
- **Behavioral humility** (`NoxBehavioralHumilityLayer`): implied intelligence — softened enrichment/resurfacing notes, Patterns shows detail lines not pattern labels.
- **Long-horizon maturity** (`NoxLongHorizonMaturityEngine`): cumulative ordering, capped emerging/behavioral visibility, softened narratives.
- **Intervention subtlety** (`NoxInterventionSubtletyPass`): rarer triggers, extended fragmented cooldown, calmer copy, decompression-aware silence.
- **Orchestration** (`NoxContinuityMaturityOrchestrator`): wired through reflective assembly, long-horizon load, and adaptive interventions.

## Phase 11 — Ambient utility, intervention & notification maturity

Module: `Nox/Core/AmbientUtility/`

- **Continuity nudging** (`NoxContinuityNudgeEngine`, `NoxNudgeSuppressionModel`): gentle in-app nudges for unfinished continuity, recovery windows, fragmentation — never task/reminder language.
- **Life-priority topology** (`NoxPriorityTopologyEngine`, `NoxStructuralContinuityModel`): structural weighting for recurring, unresolved, and stabilizing continuity (not task prioritization).
- **Decompression** (`NoxDecompressionEngine`, `NoxRecoveryWindowModel`): passive-collapse and overload-after-coordination awareness; prefers silence when needed.
- **Adaptive calmness** (`NoxAdaptiveCalmnessEngine`): adjusts reflection density, resurfacing, intervention/notification probability from overload, focus, fragmentation, decompression.
- **Unfinished threads** (`NoxUnfinishedThreadEngine`, `NoxContinuityPersistenceModel`): resurfacing-worthy interrupted structures across time.
- **Receptiveness** (`NoxInterventionReceptivenessModel`): interruption sensitivity, deep focus, recovery openness — gates interventions and notifications.
- **Attention balance** (`NoxAttentionBalanceEngine`): subtle imbalance observations without scoring.
- **Ambient silence** (`NoxAmbientSilenceEngine`): intentional suppression during overload, fragmentation, decompression, deep focus.
- **Notifications** (`NoxAmbientNotificationEngine`, cooldown/relevance/suppression models): local macOS `UserNotifications` only; opt-in via Trust; 4h global / 12h per-kind cooldowns; calm copy only.
- **Integration**: `AppEnvironment.ambientUtilitySnapshot`; utility runs after behavioral layer; refines connector interventions; calmness passed to reflective assembly; optional `NoxContextualNudgeBanner` on Now when no intervention.

## Phase 11.5 — Ambient utility calibration

Calibration layer in `Nox/Core/AmbientUtility/Calibration/`:

- **Notification calibration** (`NoxNotificationCalibrationEngine`, `NoxNotificationFatigueModel`, `NoxNotificationTrustTracker`): adaptive cooldowns, fatigue from delivery history and interruption cost — not engagement optimization.
- **Gravity evolution** (`NoxContinuityGravityEvolutionEngine`): continuity importance accrues/decays over weeks from recurrence, re-entry, and fading.
- **Experiential priority** (`NoxExperientialPriorityEngine`): significance beyond raw structural weights.
- **Decompression maturity** (`NoxDecompressionMaturityEngine`, `NoxRecoveryQualityModel`): passive collapse vs restorative recovery vs overload loops.
- **Interruption cost** (`NoxInterruptionCostEngine`): gates notifications, nudges, and interventions during high-cost moments.
- **Ambient trust** (`NoxAmbientTrustModel`, `NoxAmbientTrustState` in `NoxAmbientState`): system becomes more restrained when trust uncertainty rises.
- **Utility refinement** (`NoxUtilityRefinementEngine`): fewer nudges, higher-confidence unfinished threads, suppressed low-value notifications.
- **Silence refinement** (`NoxSilenceRefinementEngine`): state-aware silence primitive.
- **Long-horizon relevance** (`NoxLongHorizonRelevanceEngine`): cumulative thread/arc prioritization for long-horizon surfaces.
- **Orchestration** (`NoxAmbientUtilityCalibrationOrchestrator`): runs after Phase 11 base refresh on every memory reload.

## Phase 12 — Long-term memory evolution

Module: `Nox/Core/MemoryEvolution/`

- **Memory aging** (`NoxMemoryAgingEngine`, `NoxMemoryDecayModel`, `NoxTemporalDistanceModel`): gradual fade bands (active, fading, dormant, archival, resurfacing) with temporal distance — not static storage.
- **Long-horizon continuity** (`NoxLongHorizonContinuityEngine`): multi-month recurring structures and cadence evolution.
- **Identity consistency** (`NoxIdentityContinuityEngine`, `NoxBehavioralConsistencyModel`): stable rhythm and recovery tendencies — not personality typing.
- **Era evolution** (`NoxEraEvolutionEngine`, `NoxEraTransitionModel`): soft overlapping era resonance from typed memories.
- **Unresolved persistence** (`NoxUnresolvedPersistenceEngine`): long-gap continuity that stays open vs brief interruption.
- **Memory ecology** (`NoxMemoryEcologyEngine`): cross-influence between strengthening and fading structures.
- **Temporal weight evolution** (`NoxTemporalWeightEvolutionEngine`): importance accrues/decays over months from recurrence, resilience, and resurfacing.
- **Continuity resilience** (`NoxContinuityResilienceEngine`): durability across interruptions and overload.
- **Long-term resurfacing** (`NoxLongTermResurfacingEngine`): rare dormant-return notes (7-day cooldown) — quiet, meaningful.
- **Temporal coherence** (`NoxTemporalCoherenceEngine`, `NoxMemoryEvolutionOrchestrator`): global sparse tuning pass; state persisted in `NoxAmbientState.memoryEvolution`.
- **Integration**: runs after utility calibration; feeds long-horizon loader priorities, reflective resurfacing, and Patterns “Temporal continuity” section.

## Phase 12.5 — Memory evolution UX pass

Presentation layer in `Nox/Core/Memory/Presentation/` (no new dashboards or analytics):

- **Aging presentation** (`NoxMemoryAgingPresenter`, `NoxMemoryTemporalState`, `NoxTimelineRowPresentation`): maps engine aging bands to visual emphasis (title/metadata/icon opacity, duration suppression) — presentation only.
- **Temporal copy** (`NoxTemporalContinuityCopyBuilder`): replaces telemetry phrasing (“1m”, “N resumptions”) with calm continuity language — **confidence-gated**, **period-aware** (`today` vs `lastSevenDays`), stable fallbacks (`stamp ?? durationText`).
- **Row orchestration** (`NoxTemporalMemoryRowPresenter`): enriches timeline sections after Phase 12 in `NoxContextService.reloadMemoryView()`; injects rare long-term resurfacing rows (**Today only**); relation lines **Today only**; short activity rows may hide duration when ≤2 minutes.
- **Ecology hints** (`NoxMemoryRelationPresenter`): sparse relation lines when coupling threshold met.
- **UI extraction**: `NoxTimelineRowView`, `NoxTimelineSectionView`, `NoxMemoryEraObservationView`; cards (`NoxContinuityThreadCard`, `NoxSemanticArcCard`) read `memoryEvolutionSnapshot` for aging/copy.
- **Ordering (long-horizon only)**: `NoxLongHorizonLoader` and `NoxContextualMemoryPrioritizer` use `temporalWeights` for thread/arc priority — **not** timeline row order inside Memory layers.
- **Stability fixes**: single timeline publish per reload; `NoxUnresolvedPersistenceEngine` does not increment return counters on every evolve pass (prevents copy flicker).

## Interaction & Hover

- `NoxBorderlessPressStyle` — press feedback + ambient hover on **Button** labels only.
- `NoxAmbientHover` styles: `row`, `chip`, `card`, `inset` — suppressed when `isSelected`.
- `noxInteractiveChrome()` — ambient hover on **Toggle** and **Picker** only; row labels use `.allowsHitTesting(false)`.
- No hover on: timeline fragments, semantic arc cards, section headers, search field, or descriptive text.

## Testing

- Unit tests cover presence, memory, continuity, context QA, reflective continuity, **Phase 9 connectors**, **Phase 10 behavioral intelligence**, **Phase 12 memory evolution**, **Phase 12.5 presentation copy/aging**, **timeline dedup by time overlap**, **layered sections**, **historical empty copy**, and **activity classification** (e.g. ChatGPT → Research, legacy `unknown` resolution).
- UI test files exist; product strategy avoids brittle layout UI tests as primary validation.

## Current Gaps And Risks

- Reflection synthesis is deterministic only; optional LLM pass is not integrated.
- **`NoxLongHorizonView` is unwired** — consolidated long-horizon layout exists only as a component file, not a shipped destination.
- **`NoxAtmosphericState.evening`** is defined (night image + palette) but the shell never selects it; only day / night / deepReflection from `colorScheme` + window mode.
- Night aurora is a **static image plate**, not reactive to memory density or live presence (density only affects base haze slightly).
- Mail/Slack native metadata connectors are not integrated; communication pressure uses local activity proxies.
- No cloud sync, encrypted export, or backup workflow.
- Calendar permission onboarding may still need product polish; sandbox entitlement flow should be validated before release.
- Settings row labels are not tap-to-toggle (only the switch/picker is interactive).
- `Docs/CURRENT_FUNCTIONALITY.md` must stay aligned with code after visual/atmosphere changes (this file is the inventory of record).

## Best Next-Step Candidates

- Optional on-device reflective synthesis pass (still non-chat).
- Additional passive connectors (Mail/Slack metadata) with the same generalized-state contract.
- Stronger permission/onboarding for awareness tiers.
- Tap entire settings row to toggle (optional UX improvement).
