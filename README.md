# Nox

Nox is a local-first ambient memory layer for macOS.

It lives in the menu bar, opens a calm floating panel, observes local context quietly, and builds deterministic continuity from metadata and interaction aggregates. It is not a chatbot, coach, productivity dashboard, cloud assistant, screenshot recorder, clipboard tracker, or keystroke logger.

## What Nox Does Today

### Shell And Presence

- Native macOS agent app using `LSUIElement`
- Persistent menu bar item via `NSStatusItem`
- Floating adaptive panel with compact, expanded, and deep reflection modes
- Derived presence states such as quiet, active, focused, flow, idle, limited, and unavailable
- Rule-based work session detection and restart recovery
- Live context signals in the menu bar and panel

### Local Context Awareness

- Frontmost app, app switches, idle state, wake/sleep, screen lock, and periodic activity snapshots
- Window title and browser URL only when macOS permissions allow
- Interaction semantics from typing/scroll/pointer aggregates, never typed text
- Deterministic browser/workflow classification: development, research, travel, AI tools, passive media, file transfer, games, communication, creative work, and more
- Sensitive/private contexts generalized before display or storage
- Explainable inference in Debug builds

### Memory

- Hot layer: in-memory signals for current inference
- Warm layer: recent local timeline events and activity spans
- Cold layer: semantic spans, sessions, continuity threads, typed memories, compressed rollups, and reflections
- Layered memory timeline: continuity, semantic memory, focus, activity, interruptions
- Day-level semantic framing and long-horizon patterns
- Deterministic morning summaries, emerging memory states, semantic arcs, and reflection candidates
- Local persistence under `~/Library/Containers/dev.nox.Nox/Data/Library/Application Support/Nox/`

### Connector-Aware Continuity

- Optional Calendar timing profile via EventKit, generalized and local
- Communication pressure inferred from local activity proxies, not inbox contents
- Cadence, transitions, recovery signals, and rare cooldown-protected interventions
- Connector trust controls for toggles, pause, and clearing connector-derived continuity

Calendar support is implemented in code. Before treating it as release-proven, validate the final sandbox entitlement and permission flow for the packaged app.

### Privacy Boundaries

- Nox excludes itself from behavioral memory
- No cloud sync
- No LLM summaries or chat UI
- No screenshots or screen replay
- No clipboard capture
- No typed text or keystroke content storage
- No raw browser page contents or full inbox/message ingestion

## Requirements

- macOS 14.0+
- Xcode 15+ (Xcode 16+ recommended)

## Run

For normal daily use, install the standalone Release app:

```bash
./scripts/release-local.sh
```

This builds the `Nox` Release scheme, safely installs `/Applications/Nox.app`, and launches that installed app. Thereafter, open Nox from Applications, Spotlight, or its **Launch Nox at login** setting rather than from a debugger.

For development:

1. Open `Nox.xcodeproj`
2. Scheme **Nox** -> **My Mac**
3. Press **Cmd-R**

Menu bar icon -> **Open Nox**. **Quit Nox** exits fully.

For permission-sensitive testing, build and launch the standalone app from a stable path. See `Docs/DEV_IDENTITY.md`.

Installed-app workflow, login launch, local data, uninstall, and reset instructions are in [Docs/LOCAL_INSTALL.md](Docs/LOCAL_INSTALL.md).

## Tests

```bash
xcodebuild -scheme Nox -destination 'platform=macOS' test -only-testing:NoxTests
```

## Documentation

- [Docs/CURRENT_FUNCTIONALITY.md](Docs/CURRENT_FUNCTIONALITY.md) - source of truth for shipped behavior
- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) - current runtime and system architecture
- [Docs/ROADMAP.md](Docs/ROADMAP.md) - shipped phases and next candidates
- [Docs/PROJECT_RULES.md](Docs/PROJECT_RULES.md) - development and product rules
- [Docs/DEV_IDENTITY.md](Docs/DEV_IDENTITY.md) - bundle identity and permission testing
- [Docs/LOCAL_INSTALL.md](Docs/LOCAL_INSTALL.md) - standalone Release installation and login launch
- [Docs/CONTEXT_QA_MATRIX.md](Docs/CONTEXT_QA_MATRIX.md) - scenario-class context validation

## Philosophy

Nox remembers the shape of your day: patterns, continuity, and context without surveillance replay or productivity scoring.
