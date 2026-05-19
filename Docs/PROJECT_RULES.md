# Nox Project Rules

These rules are mandatory for future development.

## 1. Native-First Rule

Nox must remain a native macOS app. No Electron, Tauri, or web-wrapper architecture unless explicitly approved.

## 2. Local-First Rule

Data belongs locally by default. External APIs may be optional connectors, but never the primary source of truth.

## 3. No Raw Surveillance Rule

Nox must not store raw sensitive user content long-term by default.

Allowed long-term:

- events
- metadata
- deterministic summaries
- semantic links
- user-approved settings
- generalized connector signals

Not allowed long-term by default:

- full email or message bodies
- raw browser page contents
- passwords or auth contents
- raw long-term audio
- copied private text
- screenshots or screen replay
- typed text or keystroke content
- unnecessary full content dumps

## 4. Permission Dignity Rule

Every permission must have:

- user-visible reason
- minimal scope
- clear disconnected, connected, limited, and error states where applicable
- revocation path

No silent permission creep.

## 5. Ambient Product Rule

Nox must feel calm, subtle, and system-like.

Do not build:

- chatbot UI
- productivity dashboard framing
- gamified streaks
- nagging prompts
- manipulative coaching

## 6. No AI Slop Rule

Do not generate large generic abstractions. Do not create unused protocols, placeholder services, future-ready code that is not exercised, or comments that restate obvious code. Do not add TODOs without owner/context.

## 7. Small File Rule

- No Swift file should exceed 250 lines without a strong reason.
- No SwiftUI view should exceed 150 lines without decomposition.
- No function should exceed 40 lines without a strong reason.

Existing larger files should be reduced opportunistically when touched, not churned without cause.

## 8. Feature-First Folder Rule

- Feature UI belongs in `Features/<FeatureName>`.
- Shared design primitives belong in `Core/DesignSystem`.
- App bootstrapping belongs in `App`.
- Runtime/domain logic belongs in the relevant `Core/<Domain>` folder.
- Do not create random horizontal folders like Helpers, Managers, or Misc.

## 9. Design Token Rule

No random colors, spacing, corner radii, or shadows inline. Use design tokens from `Core/DesignSystem`. Inline values are allowed only for one-off layout adjustments and must remain minimal.

## 10. State Ownership Rule

State must have one clear owner. Do not duplicate state across views. UI-facing runtime state belongs in `AppEnvironment`; orchestration belongs in focused runtime services.

## 11. Dependency Rule

Every runtime dependency must be justified in `ARCHITECTURE.md` with purpose, alternative considered, and privacy impact. No dependency may move local inference or memory into a cloud-first path.

## 12. Error Handling Rule

- No force unwraps.
- No empty catch blocks in production paths.
- No `fatalError` in production paths.
- Silent fallback is acceptable only when the user-facing state remains honest and degraded capability is surfaced.

## 13. Privacy Language Rule

UI copy must not sound like surveillance.

Avoid phrases like:

- tracking you
- monitoring everything
- productivity score

Prefer:

- observing local activity
- local context
- presence
- continuity
- memory
- signals

## 14. Testing Rule

Core logic must be testable outside SwiftUI views. Prefer deterministic unit tests for context, memory, continuity, privacy, and connector logic. UI tests may exist, but do not make brittle static layout tests the primary validation strategy.

## 15. Phase Discipline Rule

Each phase should ship a coherent capability with an observable product effect. Keep active acceptance criteria in `ROADMAP.md`; once shipped, fold factual behavior into `CURRENT_FUNCTIONALITY.md` and retire stale phase checklists.

## 16. Current Functionality Ledger Rule

After every development phase, update `Docs/CURRENT_FUNCTIONALITY.md` to match the functionality that actually exists in code.

The ledger must describe shipped behavior, persistence, privacy boundaries, UI surfaces, tests, and known gaps. It must not become a roadmap, wishlist, or aspirational feature list.
