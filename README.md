# Nox

Nox is a **local-first ambient memory layer** for macOS.

It lives in the menu bar and opens a calm floating panel. It observes context quietly on your Mac — not a chatbot, coach, or productivity dashboard.

## What Nox does today

### Observation & presence
- Frontmost app, switches, idle time, wake/sleep, screen lock
- Derived presence states (quiet, active, focused, flow, idle, …)
- Work session detection (rule-based)
- Live context signals in the menu bar and panel

### Semantic awareness (local, deterministic)
- Interaction semantics from typing/scroll/mouse **aggregates** — never keystroke content
- Browser/workflow classification (development, research, travel, AI tools, …)
- Sensitive/private contexts stored with minimal detail
- Explainable inference (confidence + internal reasoning chain)

### Memory
- **Hot layer** — in-memory signals for inference (seconds–minutes)
- **Warm layer** — recent timeline events (days–weeks, pruned)
- **Cold layer** — semantic memory spans, sessions, typed memories, compressed rollups
- Human-readable **semantic memory blocks** (stitched continuity sessions)
- Day-level semantic framing (“shape of today”)
- Persists in `~/Library/Containers/dev.nox.Nox/Data/Library/Application Support/Nox/`

### Privacy & boundaries
- **Self-exclusion** — Nox never enters its own behavioral memory
- No cloud, no LLM summaries, no screenshots, no clipboard, no typed text storage
- Everything stays on device

## Requirements

- macOS 14.0+
- Xcode 15+ (Xcode 16+ recommended)

## Run

1. Open `Nox.xcodeproj`
2. Scheme **Nox** → **My Mac**
3. **⌘R**

Menu bar icon → **Open Nox** (⌘O). **Quit Nox** exits fully.

## Tests

```bash
xcodebuild -scheme Nox -destination 'platform=macOS' test -only-testing:NoxTests
```

## Documentation

- [Docs/PROJECT_RULES.md](Docs/PROJECT_RULES.md)
- [Docs/CURRENT_FUNCTIONALITY.md](Docs/CURRENT_FUNCTIONALITY.md) — living inventory of shipped functionality
- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)
- [Docs/ROADMAP.md](Docs/ROADMAP.md)
- [Docs/DEV_IDENTITY.md](Docs/DEV_IDENTITY.md) — stable bundle id & permissions
- [Docs/CONTEXT_QA_MATRIX.md](Docs/CONTEXT_QA_MATRIX.md) — context validation by scenario class

## Philosophy

Nox remembers the **shape** of your day — patterns, continuity, and context — without surveillance replay or productivity scoring.
