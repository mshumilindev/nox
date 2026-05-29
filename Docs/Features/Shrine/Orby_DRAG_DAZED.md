# Orby — Post-Drag Dazed (Gesture Classifier)

**Parent:** [Orby.md](Orby.md) · **Related:** [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md)

## Core rule

**Dazed is not a drag-complete animation.** It is a **high-energy gesture reaction** (fling, shake, violent jerk). Normal repositioning must never trigger dazed.

## Removed (wrong)

```swift
// Do NOT use distance + duration only:
if dragDistance >= 56 && dragDuration >= 0.3 { startPostDragDazed() }
```

## Classifier

| File | Role |
|------|------|
| `OrbyDragGestureTracker` | In-memory samples during drag |
| `OrbyDragGestureMetricsBuilder` | duration, pathLength, peak/release speed, acceleration, direction changes |
| `OrbyDragGestureClassifier` | `normal` vs `dazed(reason:)` |

### Trigger paths (throw-only; no combined-score fallback)

- **A — Throw / fling:** short (`≤ 0.42` s), straight (`net/path ≥ 0.68`), far (`≥ 96` pt), `releaseSpeed ≥ 2600`, `peakSpeed ≥ 2200`
- **B — Violent sustained drag:** `peak ≥ 3400`, `avg ≥ 1500`, `release ≥ 2000`, `net ≥ 110` pt
- **C — Shake:** `directionChangeCount ≥ 5`, `path ≥ 200`, `net/path ≤ 0.48`, `peak ≥ 1600`
- **D — Jerk:** `peakAcceleration ≥ 12000` with release + displacement guards

Quick reposition (even fast) must stay **normal**. Distance or peak speed alone never triggers dazed.

## Release flow

1. `mouseUp` → `OrbyDragGestureTracker.finish()`
2. `OrbyDragGestureClassifier.classify(metrics)`
3. Save position (once)
4. `OrbyDragPhysicsSimulator.release(dazed:)` — visual spring-back (see [Orby_DRAG_PHYSICS.md](Orby_DRAG_PHYSICS.md))
5. `.dazed` → `postDragDazed`; `.normal` → awake / hoverExcited

Deformation intensity does **not** trigger dazed; only classifier output does.

## Visual while dazed

- **External:** 4 yellow cartoon stars (~3.5 s) — [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md) §6
- **Face:** eyes **9×6**, `eyelidClosure` **0.46**; mouth **closed sleep slit** at **0.68** opacity (static — no asleep breathing)
- Cursor follow off; micro timer paused

## Tests

`NoxTests/Mac/OrbyDragGestureClassifierTests.swift` — slow drag, fling, shake, distance-only, etc.

## Debug

`Logger` category `OrbyDragDazed` in **DEBUG** only.
