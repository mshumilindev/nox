# Phase 14 — Interface Closure & Product Coherence

Goal: turn Nox from advanced ambient systems into a coherent, calm, production-feeling macOS product.

**Not in scope:** new intelligence layers, LLM, cloud sync, chat UI, productivity scoring.

## Delivered in codebase

| Area | Status |
|------|--------|
| Human observation copy rules | `Docs/NOX_UI_COPY_RULES.md` |
| Mesh-only profile isolation | `NoxPersistencePaths` — `timeline.db` always under `~/Library/Application Support/Nox/`; mesh under `PresenceMesh/` or `PresenceMesh/Profiles/<name>/` |
| Settings row-wide toggles | `NoxSettingsToggleRow` in Trust / Memory / Connector / System controls |
| Copy pass (engine → human) | Observatory, drift, patterns, trust, onboarding, capabilities |
| Menu bar | Existing `NoxStatusBarController` (autosave status item, outside-click dismiss, multi-screen clamp) |

## MVP walkthrough checklist

1. First launch → permission onboarding (calm, optional steps)
2. Activity awareness → timeline fills
3. Threads / patterns → recurring activity language
4. Reflections → infrequent summaries, not advice
5. Observatory → trend view, human observations
6. Presence → local device discovery; mesh profile does not empty memory
7. Trust → boundaries, row toggles, clear capability states
8. Quiet mode / restart → continuity of data path

## Remaining polish (optional)

- Deeper menu bar wake/sleep audit on hardware
- Further surface spacing tokens audit
- Migrate legacy `Nox-dev-*` folders if devs had split databases (manual one-time)
