# Nox Roadmap

Last updated: 2026-05-19

The old day-by-day MVP checklist has been retired. Nox is now tracked by shipped capability phases and current gaps. `Docs/CURRENT_FUNCTIONALITY.md` remains the source of truth for what exists in code today.

## Shipped Phases

| Phase | Status | Shipped capability |
| --- | --- | --- |
| 1 | Shipped | Native menu-bar identity, local-first product rules, calm presence language |
| 2 | Shipped | Floating panel, single-window orchestration, menu actions |
| 3 | Shipped | Local activity observation, permissions, SQLite event timeline, derived presence |
| 4 | Shipped | Structured memory: spans, interruptions, focus blocks, classification, search |
| 5 | Shipped | Interaction semantics, sensitive-context handling, semantic inference |
| 6 | Shipped | Context acquisition framework, adapter registry, explainability, scenario QA |
| 7 | Shipped | Reflective continuity: morning summaries, emerging memory, arcs, reflections |
| 8 | Shipped | Adaptive ambient shell, semantic navigation, trust surfaces, memory controls |
| 8.5-8.7 | Shipped | Human UI pass: surface hierarchy, layered timeline, calmer trust and Now surfaces |
| 9 | Shipped in code | Connector-aware ambient continuity: calendar timing, communication pressure proxies, cadence, transitions, recovery signals, rare interventions |
| 10 | Shipped in code | Emergent behavioral intelligence: pattern engine, expectations, adaptive continuity weighting, temporal rhythm, life structures, drift, adaptive intervention timing, memory prioritization, orchestration substrate |
| 10.5 | Shipped in code | Continuity maturity: reflection naturalization, gravity/salience, suppression, contextual relevance, behavioral humility, long-horizon maturity, intervention subtlety |
| 11 | Shipped in code | Ambient utility: contextual nudging, decompression/silence, receptiveness, adaptive calmness, macOS ambient notifications (opt-in) |
| 11.5 | Shipped in code | Utility calibration: notification fatigue/trust, gravity evolution, interruption cost, silence refinement, long-horizon relevance |
| 12 | Shipped in code | Memory evolution: aging, long-horizon continuity, identity consistency, era evolution, ecology, temporal weights, long-term resurfacing |

## Current Product Boundary

Nox currently works as a local deterministic ambient memory layer. It observes local activity metadata, derives semantic context, builds structured memory, and surfaces continuity without chat, cloud sync, productivity scoring, screenshots, clipboard capture, or typed text storage.

Phase 9 connector functionality is implemented, but calendar access should receive release-level sandbox/entitlement validation before being treated as fully production-proven.

Phase 10 behavioral intelligence is wired into memory reload and long-horizon surfaces; orchestration signals remain internal substrate only (no autonomous actions).

## Next Candidates

| Priority | Candidate | Why |
| --- | --- | --- |
| P0 | Validate Calendar permission and entitlement flow | Calendar code exists; release packaging needs confidence |
| P1 | Update permission onboarding for awareness tiers and Calendar | Current capability is stronger than the first-launch explanation |
| P1 | Add native Mail/Slack metadata connectors | Communication pressure currently uses local activity proxies |
| P1 | Tune long-horizon density on real memory | Long-horizon surfaces can grow crowded as rollups accumulate |
| P2 | Add encrypted local export/backup | Current storage is local-only without portability |
| P2 | Optional on-device reflective enhancement | Could improve reflections without introducing chat/cloud behavior |
| P2 | Make full settings rows tappable | Current controls only toggle via switch/picker |

## Non-Goals

- Cloud sync as a primary memory source
- Chatbot UI
- Productivity scores, streaks, badges, or coercive coaching
- Raw screen replay, screenshots, clipboard history, or keystroke logging
- Full inbox/message/browser-page ingestion

## Documentation Policy

Historical acceptance files were removed once they stopped reflecting the current product surface. Future phase acceptance criteria should either live in this roadmap while active or be folded into `CURRENT_FUNCTIONALITY.md` after shipping.
