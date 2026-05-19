# Nox Architecture

## Product intent

Nox is a **local-first ambient personal intelligence layer** for macOS. It observes local context over time, stores metadata—not raw surveillance by default—and surfaces calm presence in the menu bar. It must never feel like a chatbot, dashboard, or generic AI assistant.

## Why native SwiftUI

| Reason | Detail |
|--------|--------|
| System fit | Menu bar apps should feel native; `MenuBarExtra` is the Apple-intended path. |
| Performance | No Electron/Tauri overhead; low idle footprint. |
| Privacy posture | Local-first logic stays on-device; no web runtime in the hot path. |
| Long-term | Event timeline, app tracking, and reflection can use AppKit/Swift where needed without a wrapper. |

## Current stack (Days 1–2)

| Layer | Choice |
|-------|--------|
| Language | Swift 5 |
| UI | SwiftUI + AppKit window bridge |
| Lifecycle | SwiftUI `App` |
| Menu bar | `MenuBarExtra` (`.window` style) |
| Floating panel | `NoxWindowController` (`NSWindow` + `NSHostingController`) |
| State | `@Observable` `AppEnvironment`, `NoxPanelState` |
| Platform | macOS 14+ only |
| Sandboxing | App Sandbox enabled |
| Agent mode | `LSUIElement` (no Dock icon) |

No third-party runtime dependencies.

## Folder structure

```
Nox/
  App/
    NoxApp.swift              @main, MenuBarExtra
    AppEnvironment.swift      presence + version metadata
    NoxPanelState.swift       dashboard open/focus API
  Core/
    DesignSystem/             tokens, typography, spacing
    Models/                   NoxPresenceState
    Windowing/
      NoxWindowController.swift   single floating NSWindow
  Features/
    MenuBar/                  dropdown UI
    Dashboard/                floating panel UI
  Resources/
    Assets.xcassets           semantic colors, app icon
  SupportingFiles/
    Info.plist                LSUIElement, display name
Docs/                         rules, architecture, roadmap
NoxTests/                     model tests
```

## Structured memory (Day 4+)

```
timeline_events (raw)
       ↓
NoxMemoryAggregator → activity_spans, interruptions
       ↓
NoxFocusInterruptionEngine → focus_blocks
       ↓
NoxSemanticMemoryEngine → semantic_spans (stitched)
       ↓
NoxTimelineBlockPresenter → human-readable memory blocks
```

- **Classification:** `NoxAppClassifier`, `NoxTitleClassifier`, `NoxDomainClassifier`
- **Metadata:** `NoxMetadataExtractor` + `NoxTitleSanitizer`
- **Semantic inference:** `NoxSemanticInferenceEngine` + `NoxSemanticLabelCatalog` (deterministic, local)
- **Continuity:** `NoxSemanticSpanStitcher` merges nearby spans with compatible workflow keys
- **Day framing:** `NoxDaySemanticFraming` — one calm sentence at top of Today
- **Query:** `NoxMemoryQuery` + `NoxMemoryStore.searchSpans`
- **Compression:** hourly → daily → weekly → monthly → quarterly → yearly → **era** rollups
- **Typed memory:** `NoxTypedMemoryStore` for long-horizon entities (patterns, rhythms, workflows)
- **Stats:** `NoxBehavioralStatistics` (internal only — not surfaced as productivity metrics)

## Semantic & privacy (Day 5)

- **Interaction semantics:** typing/scroll/mouse aggregates — never keystroke content
- **Live signals:** `NoxSemanticLiveSignalPresenter` — 120s cooldown, context fingerprint dedup, raised confidence threshold
- **Sensitive contexts:** banking, adult, private browsing — generalized titles, minimal storage
- **Self-exclusion:** `NoxSelfExclusion` — Nox never enters its own behavioral memory (`systemInternal` category)
- **Product copy:** UI shows memory-shaped language; qualifiers like “Likely” stay internal (`NoxSemanticConfidence`)

## Local awareness (Day 3)

```
NoxActivityObserver → NoxEventBus → NoxContextService
                         ↓              ↓
                  NoxTimelineStore   AppEnvironment → SwiftUI
                         ↓
              NoxPresenceEngine + NoxSessionDetector
```

- **Observer:** `NSWorkspace` notifications + 2s idle/window poll (not UI-driven).
- **Permissions:** `NoxPermissionService` — Accessibility required for full window context.
- **Events:** Typed `NoxEvent` / `NoxEventPayload` — no stringly-typed payloads.
- **Store:** SQLite (`timeline.db`) in app container — metadata only in display text.
- **Presence:** Rule-based `NoxPresenceEngine` — no ML, no hardcoded UI labels.
- **Sessions:** `NoxSessionDetector` — productivity app focus, rule-based confidence.

## Floating window (Day 2)

**Approach:** `NoxPanelState` exposes `openDashboard(using:)` to the menu bar. It delegates to `NoxWindowController`, which owns at most one `NSWindow`.

**Why AppKit:** `MenuBarExtra` apps do not use a `WindowGroup` for auxiliary UI. A small `NSWindow` bridge gives native materials, title bar hiding, floating level, and focus behavior without Electron or scene hacks.

**Duplicate prevention:** `NoxWindowController` keeps a single optional `window` reference. `openOrFocus` calls `makeKeyAndOrderFront` if the window exists; otherwise it creates one. `windowWillClose` clears the reference so a later open creates a fresh window.

## State ownership

- `AppEnvironment` owns `presence` (default `.quiet`) and version strings.
- `NoxPanelState` owns floating window orchestration (`isDashboardOpen`, open/close).
- Views read via `@Environment`; no DI frameworks or manager sprawl.

## Design system

- **Spacing:** `xs` / `sm` / `md` / `lg` / `xl` via `NoxSpacing`
- **Radius:** `sm` / `md` / `lg` via `NoxDesignTokens.Radius`
- **Opacity:** disabled, subtle, secondary, divider via `NoxDesignTokens.Opacity`
- **Typography:** wordmark, presence line, body, caption, actions via `NoxTypography`
- **Symbols:** sizes via `NoxDesignTokens.SymbolSize`
- **Colors:** asset catalog + `NoxDesignTokens.ColorRole`

## Current non-goals

- Cloud sync, LLM summaries, chatbot UI, coaching, gamification
- Productivity scores, streaks, badges, recommendation engines
- Keystroke logging, clipboard, screenshots, surveillance replay
- Fake or demo intelligence data in UI

## Future (optional, not started)

- Connector layer (calendar, mail, browser) as secondary inputs
- Optional encrypted backup export
- On-device reflection only if explicitly designed — never faked in UI

## Dependencies

**Day 1:** none (optional SwiftLint).

Every future dependency must be recorded here with purpose, alternative considered, and privacy impact.

## Testing strategy

- Unit-test models (`NoxPresenceState`, `AppEnvironment` defaults)
- Keep logic out of SwiftUI views as features grow
- Skip brittle UI tests for static Day 1 menu layout

## Security & privacy baseline

- App Sandbox on
- No permission prompts on Day 1
- No network on Day 1
- UI copy avoids surveillance language; future states use honest “later step” wording
