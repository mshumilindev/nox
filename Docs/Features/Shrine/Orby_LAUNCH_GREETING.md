# Orby — Launch greeting (silent “Hello”)

**Parent:** [Orby.md](Orby.md) · **Status:** Implemented (macOS Mini Shrine)

## Purpose

When Orby is **manually shown** after being hidden, he briefly smiles and silently mouths “Hello” using the **same morphing mouth** as all other phases — no text, no audio, no speech synthesis.

## Triggers

| Play greeting | Do not play |
|---------------|-------------|
| Toggle Orby **on** from menu bar (show at default placement) | Orby already visible (state update only) |
| First manual show in app session | Wake from sleep / idle sleep ritual |
| Any later manual show/toggle in same session | Drag, reposition, Space restore |
| | Automatic urgent notification show (future) |

Implementation: `ShrineSurfaceController.showMiniAtDefaultPosition()` → `OrbyMiniVisualController.noteShow(playLaunchGreeting: true)`.

## Replay rule

- Plays on **every manual Mini Shrine toggle/show**.
- No session cooldown. If the user hides and shows Orby, Orby says hello again.

## Phase

`launchGreeting(progress: 0…1)` — duration **5.4 s** (`launchGreetingDurationSeconds`): **2.0 s** friendly smile hold, then **3.4 s** silent “Hello” (~1.05 s mouth motion, **2.0 s** assembled word hold, ~0.35 s fade).

### Priority (after dragging / menu / dazed)

1. dragging  
2. context menu  
3. postDragDazed  
4. **launchGreeting**  
5. hoverExcited  
6. waking*  
7. sleepyTransition  
8. asleep  
9. awake + mood  

## Timeline (mouth)

Progress-driven keyframes (`OrbyLaunchGreetingAnimator` + `OrbyLaunchGreetingMouth`). For the first **2.0 s**, the mouth forms as `smileSeed` → `smileGreeting`: corner lift and curvature arrive first, width follows, so the smile does not begin as a flat horizontal stretch. The Hello visemes below run only after that hold.

| Time | Viseme | Shape intent |
|------|--------|--------------|
| 0.00–2.00 s | smileSeed → smileGreeting | Friendly closed smile hold; lift before width |
| 2.15–2.65 s | helloHe | **One** open “he” |
| 2.65–2.85 s | helloHe → helloLlo | Direct morph to “llo” (no narrow L robot step) |
| 2.85–4.85 s | helloLlo | Rounded “llo” while **Hello** particles hold at the arc peak |
| 5.20–5.40 s | smileSettle | Gentle smile hold |

Interpolation: `OrbyMouthParameters.interpolated` + smoothstep between keyframes — **one** `OrbyMouthView`, no view crossfade.

## Eyes / body

- Eyes open, friendly; **no** ambient blink during greeting.
- Soft **cheek blush** ramps in during smile phases (~0.22–0.8 strength); see [Orby_CHEEK_BLUSH.md](Orby_CHEEK_BLUSH.md).
- Cursor-follow **reduced** first ~0.8 s, full follow by end (`eyeTrackingFactor` curve).
- Subtle appear scale **0.96 → 1.02 → 1.0** (~0.46 s) via `appearScale(progress)`.
- During the smile hold, a tiny breathing lift keeps the greeting alive without starting speech too early.
- During Hello, small eye offsets, head nod/turn, glow, blush, and orb pulse accents follow **he** then **llo** (two beats, not three).
- Syllable particles: **`He`** and **`llo`** launch from the mouth, drift to a shared arc peak, and **hold for 2.0 s** as assembled **Hello** (`OrbyLaunchGreetingSyllableTiming`) before fading. On-orb text white; off-orb deep purple (light) or white (dark).
- Slightly warmer tint; no Zzz / dazed particles.

## After greeting

- Phase → `awake` or `hoverExcited` if cursor was over orb (deferred during greeting).
- Mouth settle → resolved mood mouth (~0.45 s, existing `mouthSettle` path).
- Baseline blink suppressed **1.5–3.0 s** after end (`postIdleBlinkDelayRange`).
- Cursor idle / sleep timer reset from greeting end.

## Interruption

| Action | Result |
|--------|--------|
| Drag | `cancelLaunchGreeting()` → dragging |
| Click (open Full Shrine) | Cancel → `noteUserInteraction` → open window |
| Right-click | Cancel → context menu |
| Hover during greeting | Deferred; hoverExcited after complete |

## Files

| File | Role |
|------|------|
| `OrbyLaunchGreetingMouth.swift` | Viseme parameter presets |
| `OrbyLaunchGreetingSyllableTiming.swift` | Particle flight + 2 s Hello hold |
| `OrbyLaunchGreetingAnimator.swift` | Timeline + interpolation |
| `OrbyMiniVisualController.swift` | Phase, trigger, cooldown, interrupt |
| `OrbyEmotionCompositor.swift` | `launchGreeting` appearance |
| `OrbyMiniVisualTiming.swift` | Duration / cooldown constants |

## QA

See acceptance checklist in product task; manual: hide → Toggle Orby → watch silent hello → no text/sound → interact to interrupt.
