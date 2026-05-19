# Nox Project Rules

These rules are **mandatory** for all future development.

## 1. Native-first rule

Nox must remain a native macOS app.
No Electron, no Tauri, no web-wrapper architecture unless explicitly approved later.

## 2. Local-first rule

Default assumption: data belongs locally.
External APIs are only connectors, never the primary source of truth.

## 3. No raw surveillance rule

Nox must not store raw sensitive user content long-term by default.

**Allowed long-term:**

- events
- metadata
- summaries
- semantic links
- user-approved settings

**Not allowed long-term by default:**

- full email bodies
- raw browser page contents
- passwords
- raw long-term audio
- copied private text
- unnecessary full content dumps

## 4. Permission dignity rule

Every permission must have:

- user-visible reason
- minimal scope
- clear disconnected/connected/error state
- revocation path

No silent permission creep.

## 5. No AI slop rule

Do not generate large generic abstractions.
Do not create unused protocols.
Do not create placeholder services unless needed by the current day.
Do not create “future-ready” code that is not used.
Do not write comments that restate obvious code.
Do not add TODOs without owner/context.

## 6. Small file rule

- No Swift file should exceed **250 lines** without a strong reason.
- No SwiftUI View should exceed **150 lines** without decomposition.
- No function should exceed **40 lines** without a strong reason.

## 7. Feature-first folder rule

- Feature UI belongs in `Features/<FeatureName>`.
- Shared design primitives belong in `Core/DesignSystem`.
- App bootstrapping belongs in `App`.
- Do not create random horizontal folders like Helpers, Managers, Misc.

## 8. Design token rule

No random colors, spacing, corner radii, or shadows inline.
Use design tokens from `Core/DesignSystem`.
Inline values are allowed only for one-off layout adjustments and must remain minimal.

## 9. State ownership rule

State must have one clear owner.
Do not duplicate state across views.
Use simple local state on Day 1.
Do not introduce global state libraries/patterns prematurely.

## 10. Dependency rule

No third-party dependencies on Day 1 except SwiftLint if configured.
Every future dependency must be justified in `ARCHITECTURE.md`.

## 11. Error handling rule

- No force unwraps.
- No silent failures.
- No empty catch blocks.
- No `fatalError` in production paths.

## 12. Privacy language rule

UI copy must not sound like surveillance.

**Avoid** phrases like “tracking you”.

**Prefer:**

- observing activity
- local context
- presence
- timeline
- signals

## 13. Ambient product rule

Nox must feel calm, subtle, and system-like.

Do not build:

- a chatbot UI
- a productivity dashboard
- gamified streaks
- nagging prompts

## 14. Testing rule

For Day 1, add simple unit tests only if the project setup supports it cleanly.
Do not create brittle UI tests for static menu layout yet.
Future logic must be testable outside SwiftUI Views.

## 15. Daily capability rule

Each development day should produce exactly **one major capability** and **one visible wow-effect**.
Do not mix Day 2/Day 3 features into Day 1.

## 16. Current functionality ledger rule

After every development phase, update `Docs/CURRENT_FUNCTIONALITY.md` to match the functionality that actually exists in code.

The ledger must describe shipped behavior, persistence, privacy boundaries, UI surfaces, tests, and known gaps. Do not let it become a roadmap, wishlist, or aspirational feature list.
