# Orby — Blink, Mouth, Zzz, Wake, Dizzy Stars (Amendment)

**Parent:** [Orby.md](Orby.md) · **Status:** Implemented (macOS Mini Shrine)

## Summary

Visual polish pass: eye-shape blink/sleep (no eyelid overlays), morphing mouth, adaptive Zzz placement/color, corrected wake sequence, 4 cartoon yellow dizzy stars with pseudo-3D orbit.

## 1. Eyes — no eyelid overlays

Blink/sleep/squint = **eye height morph** only. `eyelidClosure` in API = **narrow amount** (0 open → 1 thin slit). No separate lid shapes. No opacity-only blink.

**Canonical awake layout** (`OrbyEmotionAppearance`): spacing **16**, width **9.5**, default heights **9.5 / 7.5**; all awake moods share spacing/width/shift — expression varies **height only**. `OrbyEyeMetrics.sizeScale` **1.08**. `passive` / `muted` use full `neutralDefault` eyes (not extra-dimmed slits). `eyesDimmed` reserved for `disconnected`.

## 2. Ambient blink

Close 0.10s → hold 0.05s → open 0.14s per pulse. Interval between events: mood table (e.g. neutral **3–6.5 s**) × `ambientBlinkIntervalRarityMultiplier` (**1.0**) × per-mood `blinkIntervalScale`. Each event is usually **one** blink; **~26%** chance of a **double** blink (two pulses, 0.11 s gap). Disabled: hoverExcited, drag, dazed, asleep, wake ritual, context menu.

## 2b. Cheek blush

**Canonical:** [Orby_CHEEK_BLUSH.md](Orby_CHEEK_BLUSH.md).

| Item | Shipped |
|------|---------|
| Marks | **11×5 pt** capsules, rose `(1.0, 0.42, 0.58)`, opacity **0.44** × strength |
| Placement | **50%** of eye-bottom → mouth-top gap; **eye-row overlay** (does not push mouth) |
| Horizontal | **2.5 pt** outward per cheek from eye center |
| Edge | **2.5 pt** blur per mark only |
| Fade | **0.24 s** in / **0.28 s** out on strength |
| Layer | Behind eyes |

## 3. Sleep / wake

- `sleepyTransition` ~6s: linear narrow 0→1.
- **Meaningful cursor movement during `sleepyTransition` (before `asleep`):** abort immediately → `awake` / `hoverExcited` — no yawn or wake ritual.
- `asleep`: ~1.6pt slits, optional dim opacity.
- Wake from **`asleep` only:** yawn → **exactly 2** blinks → squint → glance R/L → awake.

## Cosmic orb body (internal material)

Layer order inside `OrbyOrbChrome` orb shell (back → front): **cosmic material** (`OrbyCosmicMaterialView`: base gradient → nebula → starfield → vignette) → emotion **tint** → **stylized sky overlays** (noir, black hole) → **rim strokes** → **adaptive bezel** → face (eyes/mouth above shell). No separate gloss highlight layer.

- **Starfield:** 24 deterministic stars (`OrbyCosmicStarCatalog`), twinkle at 20 Hz opacity only, clipped to circle.
- **Nebula:** soft violet + blue/magenta clouds; ~48 s drift; center falloff for face readability.
- **Tuning:** `OrbyCosmicMaterialConfig` (`starCount`, opacity/twinkle/nebula multipliers, `faceSafeZoneDimming`).
- **Separate from** external post-drag dazed stars and sleep Zzz.
- Wake yawn (**~4.6 s**): one morphing mouth — sleepy line → **vertical rounded capsule** (preferred ~16×20 pt, clamp max 18×22); deep violet fill ~0.86 opacity when open (`OrbyFaceView`); `verticalYawnCapsule` from low openness (no wide horizontal bar first). Thin sleepy eyes (~0.93 closure) entire yawn. Hold at max ~30% of phase; head arc `OrbyWakeYawnMotion`. `startFullWake` resets mouth settle (no pre-yawn stretch/snap). **`wakePhaseGapSeconds` (~0.16 s)** between steps. **Mouth settle** (~0.45 s) after ritual only. Envelope **30×22 pt**; gaze/drag must not wrap mouth.

## 4. Mouth

Single `OrbyMouthView` / `OrbyMouthShape`: **one filled blob** (capsule or thick curve), no stroke overlay, no opacity crossfade, no second mouth view. `openness` 0→1 morphs closed bar → soft open rounded aperture; high-openness shapes must not pinch into a thin ellipse at top/bottom. `cornerLift` bends the same material for smile/frown.

## 5. Zzz

Zzz adapt to sampled background under the transparent panel: saturated violet on light backgrounds, pale lavender on dark backgrounds. Shifted up/out; no mirror; isolated from face 3D. Zzz are animated as a small outward stream: 3–4 glyphs are present across the cycle; each glyph appears near the upper-right rim, drifts along the existing diagonal path away from Orby, then fades and shrinks while a new glyph appears near the rim.

## 5b. Idle microbehaviors

Rare awake-only actions (tongue peek, bubble, wander, …). Weighted random pick with no immediate repeat when alternatives exist; gaze-only behaviors have lower weight than mouth/overlay/scale behaviors. Hover / drag / dizzy / sleep **pause** the timer (no cooldown restart). See [Orby_IDLE_MICROBEHAVIOR.md](Orby_IDLE_MICROBEHAVIOR.md). Not blink; not persisted.

## 5c. Drag deformation (visual physics)

Panel/window follows the pointer **immediately**. Elastic squash/stretch and face spring-lag are **visual only** (`OrbyDragPhysicsSimulator`).

- Slow drag → almost no deformation (`softStart` 250 pt/s, `maxVisual` 1600 pt/s).
- Fast drag → vector-aligned stretch (cap 1.10) / compression (floor 0.92).
- Face inherits ~28% of orb deformation; lag up to 6 pt via spring.
- Normal release → spring back ~0.35 s; dazed release → slightly longer wobble into stars.
- Zzz, dazed halo, hit testing, saved position **unchanged**.

Full spec: [Orby_DRAG_PHYSICS.md](Orby_DRAG_PHYSICS.md).

## 6. Dizzy (post-drag dazed)

4 yellow cartoon stars on an elliptical orbit (~1.0s per revolution); pseudo-3D front/back via size, opacity, and zIndex; ~3.5s duration.

**Trigger:** `OrbyDragGestureClassifier` only — **throw-like** release (short, straight, hot), violent sustained drag, shake, or jerk. Normal reposition never dazes. **Not** distance, duration, or deformation intensity alone. See [Orby_DRAG_DAZED.md](Orby_DRAG_DAZED.md).

**Centering:** Orbit is centered on the **painted orb** in the padded chrome canvas (`OrbyDizzyStarsGeometry.orbCenter` at canvas center — not the 76×76 face box). Canvas size follows `OrbyOrbGeometry.chromePadding` (20 pt bleed).

**Geometry (current):**

| Constant | Value | Notes |
|----------|--------|--------|
| `orbitRadiusX` | 35.2 pt | +10% vs original 32 pt |
| `orbitRadiusY` | 12.1 pt | +10% vs original 11 pt |
| `starSizeFront` | ~10.45 pt | +10% vs 9.5 |
| `starSizeBack` | ~7.15 pt | +10% vs 6.5 |
| `orbitCenterYOffset` | −38 pt | Above orb center |

## Code

| File | Role |
|------|------|
| `OrbyEyeView.swift` | Eye shape morph |
| `OrbyFaceView.swift` | Face + ambient blink |
| `OrbyMouthView.swift` | Mouth morph |
| `OrbyZzzView.swift` | Adaptive violet/lavender Zzz |
| `OrbyDazedHaloView.swift` | Dizzy stars orbit |
| `ShrineMiniVisualController.swift` | Narrow amounts + wake curves |

## Acceptance

See [Orby.md](Orby.md) §30–31: blink shape morph, wake yawn + 2 blinks + suspicious squint + right/left glances, one morphing mouth, cheek blush overlay, adaptive Zzz, 4 yellow dizzy stars, no regressions.
