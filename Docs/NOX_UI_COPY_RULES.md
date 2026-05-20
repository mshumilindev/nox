# Nox UI copy rules

Phase 14 product rule: Nox describes **observable reality** in language a person would naturally understand. The system may model continuity, cadence, and topology internally — users should mostly hear what actually happened.

## Human observation rule

Every user-facing sentence must answer:

- what happened,
- what repeated,
- what changed,
- or what Nox noticed.

Prefer **direct observations** and **plain phrasing**. Nox should sound like someone quietly noticing patterns — not a cognition engine narrating itself.

### Good

- “You moved between a lot of different things tonight.”
- “Focus stayed steady most of the morning.”
- “You came back to this after a few quieter days.”
- “Most work today happened in shorter stretches.”
- “You returned to development work after several days away.”

### Bad

- “Fragmentation increased.”
- “Continuity weakened.”
- “Behavioral instability emerged.”
- “Recovery cadence shifted.”
- “Coordination load remained elevated.”
- “Temporal continuity resurfaced.”

The user should feel: **the system quietly noticed something** — not **the system is modeling me**.

## Vocabulary

**Use:** apps, sessions, work, focus, switching, evenings, mornings, projects, viewing, messages (generalized), calendar timing.

**Avoid in UI copy:** continuity, topology, cadence, orchestration, resonance, drift, structure, fragmentation (as a noun), enrichment, semantic arc, long-horizon field, pipeline, entitlement, observation pipeline.

Internal engine terms stay in code and comments only.

## Tone

- Calm, restrained, local-first, confidence-aware.
- No sci-fi narration, therapy voice, productivity coaching, or quantified-self scoring.
- No filler: quietly, softly, gently, subtly (unless meaning changes).
- When confidence is low, say so plainly: “Patterns are still forming.” / “Not enough repeated activity yet.”

## Specificity

The factual layer is mandatory. Ambient tone is optional and must support meaning — never replace it.

If copy could appear unchanged in a meditation app, AI philosophy site, or sci-fi trailer, rewrite it.

## Implementation

Any new UI string must pass a specificity review before merge. See `Docs/PHASE_14_INTERFACE_CLOSURE.md` for scope (settings, onboarding, mesh paths, surfaces).
