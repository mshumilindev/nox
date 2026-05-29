# Feature specifications

Product- and platform-wide docs stay in [`Docs/`](../) (architecture, roadmap, migration, copy rules).

**Feature specs** in this folder describe one shippable capability: behavior as implemented (or explicitly planned), file map, acceptance criteria, and known limits. Prefer updating the feature spec when the code changes.

## Layout

```
Docs/Features/
  README.md          ← this file
  Shrine/
    Orby.md                  ← Orby: Mini Shrine face (macOS, shipped)
    Orby_EMOTION_MATRIX.md   ← Emotional state & animation matrix (amendment)
    Orby_VISUAL_POLISH.md    ← Blink, mouth morph, Zzz, wake, dizzy stars
    Orby_IDLE_MICROBEHAVIOR.md ← Rare awake idle actions (not blink)
    Orby_DRAG_DAZED.md         ← Post-drag dizzy gesture classifier
```

## Related docs (not feature specs)

| Doc | Role |
|-----|------|
| [SHRINE_SPEC.md](../SHRINE_SPEC.md) | Product definition |
| [SHRINE_ARCHITECTURE.md](../SHRINE_ARCHITECTURE.md) | Cross-surface architecture |
| [SHRINE_MACOS_SURFACE_SPEC.md](../SHRINE_MACOS_SURFACE_SPEC.md) | All macOS Shrine surfaces (planned + shipped summary) |
| [CURRENT_FUNCTIONALITY.md](../CURRENT_FUNCTIONALITY.md) | Living inventory of what runs today |
