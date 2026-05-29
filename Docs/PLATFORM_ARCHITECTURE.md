# Nox platform architecture

Human-readable reference for multi-platform boundaries. **Enforced for agents** via `.cursor/rules/nox-platform-*.mdc`.

## Canonical node

**macOS** is the only full Nox node: desktop observation, canonical SQLite memory, menu bar, window modes, full Observatory, and primary Presence Mesh.

Other Apple platforms are future consumers of shared packages; they must not duplicate canonical memory or desktop observation without an explicit sync product design.

## Repository layout

```
Packages/
  NoxPlatformContracts/   # Protocols only (Foundation)
  NoxShrineCore/          # Shrine embodiment contracts (Foundation)
  NoxCore/                # Universal primitives
  NoxContextCore/         # (planned) Context domain
  NoxMemoryCore/          # …
Apps/
  NoxMac/Nox/             # macOS app + adapters + Features/ (Xcode target)
```

Dependency direction: **Apps → adapters → Packages**. Never Packages → App.

## Three layers of code

| Layer | Universal? | Where | Imports |
|-------|------------|-------|---------|
| **Domain** | Yes — same models/engines on all platforms that ship Nox | `Packages/Nox*Core` | Foundation (+ package deps) |
| **Contracts** | Yes — capability surface | `NoxPlatformContracts` | Foundation |
| **Adapters + UI** | No — per platform | `Apps/NoxMac/Nox/`, future `Apps/NoxiOS/` | Platform frameworks |

## Capability matrix

| Capability | macOS | iPhone | iPad | Watch | TV | visionOS |
|------------|-------|--------|------|-------|-----|----------|
| Activity observation | Full desktop | — | — | — | — | Optional spatial |
| Window/app context | NSWorkspace/AX | — | — | — | — | Non-canonical |
| Canonical memory store | Yes | Read/cache | Read/cache | — | — | Cache |
| Memory browsing UI | Full | Summary | Summary | Glance | — | Summary |
| Notifications | Full | Full | Full | Short | Minimal | Subtle |
| System interventions | Focus, caffeinate, etc. | Light trust/continuity | Light | Hint | Display | Subtle |
| Presence mesh | Primary | Limited | Limited | Hint | Passive | Limited |
| Shrine surfaces | Software fallback + physical controller | Future passive/mirror | Future passive/mirror | No | Future passive/mirror | Optional |
| Observatory | Dashboard | Summary | Summary | No | No | Optional |
| Trust UI | Full | Light | Light | Minimal | None | Light |

## Platform-specific prohibitions

- **iPhone / iPad**: No desktop foreground observation, Accessibility pipeline, or canonical DB ownership.
- **watchOS**: No Observatory, full memory browser, or heavy on-device inference.
- **tvOS**: Passive/household only; no personal productivity surfaces.
- **visionOS**: Shared models OK; not canonical core.
- **Shrine**: Physical Shrine is capability-based and trusted through pairing/heartbeat. Software Shrine is a fallback surface, not canonical memory. Station support is explicit opt-in only.

## Shrine Layer

Shrine is the planned ambient embodiment layer for Nox. It can appear as macOS Notch Shrine, Floating Mini Bubble, Full Shrine Interface, physical Raspberry Pi display, or future passive/mirror Apple surfaces.

Core contracts live in `Packages/NoxShrineCore` and remain Foundation-only. macOS panels/windows/views must live in `Apps/NoxMac/Nox`. Raspberry Pi runtime must be a separate Linux-safe implementation using shared JSON-friendly contracts; do not assume the macOS SwiftUI app can run on Pi.

## Validation

```bash
Scripts/check-package-import-boundaries.sh
xcodebuild -scheme Nox -destination 'platform=macOS' -configuration Debug build
xcodebuild -scheme Nox -destination 'platform=macOS' -configuration Debug test -only-testing:NoxTests
```

Migration status: `Docs/PLATFORM_MIGRATION.md`. Decomposition guide: `Docs/PLATFORM_DECOMPOSITION.md`.
