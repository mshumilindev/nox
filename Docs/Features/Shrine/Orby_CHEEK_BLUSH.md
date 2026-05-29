# Orby — Cheek blush

**Parent:** [Orby.md](Orby.md) · **Status:** Shipped (macOS Mini Shrine) · **Canonical** for blush layout, opacity, and face integration.

## Purpose

Soft **cheek marks** on friendly/cute moments — not eye highlights, not mouth tint, not an orb-wide gradient.

## Visual constants (shipped)

| Property | Value | Code |
|----------|--------|------|
| Shape | Horizontal `Capsule` | `OrbyCheekBlushView` |
| Size | **12 × 5.5 pt** | `markWidth`, `markHeight` |
| Fill opacity | **0.62** × strength | `fillOpacity` |
| Color | Rose / pink **(1.0, 0.42, 0.58)** sRGB | `OrbyCheekBlushStyle.fill` |
| Mark blur | **2.5 pt** per capsule | `markBlurRadius` |
| Fade in | **0.24 s** easeInOut | `fadeInSeconds` |
| Fade out | **0.28 s** easeInOut | `fadeOutSeconds` |
| Outward from eye center | **2.0 pt** + **0.5 pt** per side | `outwardFromEyeCenter`, `horizontalSpreadPerSide` |
| Min clearance below eyes | **≥ 2 pt** (top of mark) | `minGapBelowEyeBottom` |
| Eye–mouth VStack gap | **6 pt** (face only) | `faceEyeMouthSpacing` ↔ `OrbyFaceView` |
| Mouth envelope height | **18 pt** (layout reference) | `mouthEnvelopeHeight` ↔ `OrbyMouthView` |
| Vertical placement | **50%** of eye-bottom → mouth-top gap | `eyeToMouthVerticalBias` |
| Layer | Behind eyes; overlay on eye row | `OrbyFaceView` ZStack |

## Layout algorithm

`OrbyCheekBlushGeometry.layout(leftEye:rightEye:eyeSpacing:)` derives positions from the **current** eye metrics (mood/phase may change eye size/shift).

1. **Eye bottom** (from top of eye row): `max(height + verticalShift)` per eye — matches `OrbyEyeView` frame + offset.
2. **Mouth top** (layout space): `eyeRowHeight + faceEyeMouthSpacing` (mouth is the next `VStack` row; envelope height used for documentation/tests only).
3. **Mark center Y**: `eyeBottom + (mouthTop - eyeBottom) × 0.5`, clamped so mark top ≥ `eyeBottom + 2 pt`.
4. **Mark center X**: each eye center ± **2.5 pt** outward (left cheek left, right cheek right).

Blush must not overlap eye rectangles. Marks may draw into the **6 pt** gap between eye row and mouth (overlay); they must **not** expand the eye-row frame (prevents eyes and mouth drifting apart).

## Face integration

```
VStack(spacing: 6) {
  eyeRow.overlay { OrbyCheekBlushView }   // blush does not affect row height
  mouth
}
```

- **Strength animation:** `OrbyFaceView` keeps `@State animatedCheekBlushStrength` and `withAnimation` on `presentation.cheekBlushStrength` changes — no pop from conditional view removal.
- **Compositor:** `OrbyEmotionCompositor` sets base `cheekBlushStrength`; `OrbyCheekBlushPolicy.resolvedStrength` applies phase/micro overrides.

**Removed:** orb-shell pink gradient (caused muddy smear across the whole orb).

## When blush shows

| Source | Strength (typical) |
|--------|-------------------|
| `hoverExcited` | 1.0 |
| `launchGreeting` | ~0.22 → ~0.80 (ramps with progress) |
| `pleased` mood | 0.55 (0.65 if strong) |
| Idle `microSmile` | ≥ 0.65 |
| Idle `tonguePeek` | ≥ 0.55 |

## When blush is off

`OrbyCheekBlushPolicy.isSuppressed`: `dragging`, `postDragDazed`, `asleep`, `sleepyTransition`, all `waking*`, and moods with compositor strength 0 (neutral, focused, concerned, annoyed, alarmed, …).

Drag: resolved strength forced to **0** even if expression were friendly.

## Not cheek blush

- Idle **`cheekPuff`** — mouth width puff only; no pink overlay.
- Menu bar Orby mark — no blush.

## Source files

| File | Role |
|------|------|
| `OrbyCheekBlushGeometry.swift` | Layout + constants |
| `OrbyCheekBlushPolicy.swift` | Phase/micro suppression |
| `OrbyCheekBlushView.swift` | Capsule draw + blur |
| `OrbyFaceView.swift` | Overlay + strength fade |
| `OrbyEmotionCompositor.swift` | Mood/phase base strength |
| `OrbyMiniVisualPresentation.swift` | `cheekBlushStrength` on presentation |

## Tests

`NoxTests/Mac/OrbyCheekBlushGeometryTests.swift` — below-eye invariant, policy suppress/allow.

## QA checklist

1. **Hover** / **launch greeting** — blush **midway** between eyes and mouth; clearly pink, not gray or washed out.  
2. **Fade in** when entering friendly state; **fade out** when leaving (no instant pop).  
3. Capsules **11×5**, soft **2.5 pt** edge blur — not pin dots, not face-wide smear.  
4. Eyes and mouth stay **6 pt** apart; blush must not push mouth down.  
5. **No** blush when dragging, asleep, sleepy, waking, or dazed.  
6. Blush follows face (gaze offset, drag lag, head turn).  
7. Horizontal: cheeks slightly **wider** than eye centers (~2.5 pt outward each side).
