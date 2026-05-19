# Day 4 Acceptance — Structured Memory

## Memory architecture

- [x] Raw `timeline_events` preserved
- [x] `ActivitySpan` model + persistence
- [x] `FocusBlock` model + persistence
- [x] `Interruption` model + persistence
- [x] Aggregation layer (`NoxMemoryAggregator`)
- [x] UI models separated (`NoxTimelineBlockItem`)

## Classification

- [x] Deterministic app/title/domain classifiers
- [x] Browser title overrides (GitHub, ChatGPT, tutorials)
- [x] Categories used in spans and UI

## Metadata

- [x] `NoxContextMetadata` + sanitizer
- [x] Cleaned window titles stored separately from raw

## Focus & interruption

- [x] Focus blocks (focused, deep work, fragmented)
- [x] Interruption records with `returnedBack`
- [x] Presence engine uses focus analysis

## Historical navigation

- [x] Today / Yesterday / Last 7 days
- [x] Loads from SQLite (no fake loading)

## Timeline UI

- [x] Grouped memory blocks (not raw log stream)
- [x] Category + duration emphasis
- [x] Focus / interruption markers

## Statistics

- [x] Subtle day stats (focused time, switches, longest block)
- [x] No gamification language

## Search

- [x] Filter by app, project/context, category text
- [x] `today` / `yesterday` query shortcuts

## Polish

- [x] Density shifts with activity richness
- [x] Calm visual style preserved

## Constraints

- [x] No AI / cloud / coaching
- [x] Build + tests pass
