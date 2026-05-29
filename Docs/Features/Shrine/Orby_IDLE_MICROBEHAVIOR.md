# Orby — Idle Microbehavior System

**Parent:** [Orby.md](Orby.md) · **Related:** [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md)

## Purpose

Rare, quiet autonomous moments while Orby is **awake** and not directly interacted with. Not persisted to memory/timeline. Does **not** reset the cursor sleep timer.

## Baseline blink (separate)

Blink is physiology, not idle microbehavior. Shipped intervals use mood table × **`ambientBlinkIntervalRarityMultiplier` (1.0)** × per-mood `blinkIntervalScale`.

| Mood | Base (s) |
|------|----------|
| neutral, curious, pleased, excited, thinking | 3–6.5 |
| focused, concerned, skeptical, overloaded | 5–10 |
| deepFocus | 8–15 |
| tired, sleepy | 2.5–5.5 |
| passive, muted | 6–12 |
| nightWatch | 7–13 |
| alarmed, annoyed, disconnected | 4–9 |

Suppressed during hover, drag, dazed, sleep/wake, context menu, and **any active idle microbehavior**. After a microbehavior ends, baseline blink waits **1.5–3.0 s**.

## Scheduling

Periodic while **awake only** — global mouse movement does **not** interrupt an active microbehavior, but entering hover cancels the active microbehavior and transitions smoothly into `hoverExcited`.

| Constant | Value |
|----------|--------|
| Initial delay after show | **5–11 s** |
| Interval / cooldown (after run) | **16–42 s** (mood-scaled via `scheduleMultiplier`; cap **60 s**) |
| Max / 5 min | **12** |
| Rare max / 30 min | 4 |
| Stylized min gap | **7 min** |
| Stylized max / hour | **4** (never back-to-back) |

### Gaze gate

A **new** microbehavior starts only when **gaze is at rest**: eye offset near center (&lt; 0.5 pt) and cursor quiet for **~0.35 s**. Active microbehaviors continue while the cursor moves.

### Timer pause (not restart)

While any of these are active, the **next micro deadline is frozen** — no new cooldown is applied when pause starts:

| State | Pauses timer |
|-------|----------------|
| **Drag** (`dragging`) | Yes |
| **Hover** (`hoverExcited`) | Yes |
| **Dizzy** (`postDragDazed`) | Yes |
| **Sleep** (`sleepyTransition`, `asleep`) | Yes |
| **Wake ritual** (all `waking*` phases) | Yes |
| **Context menu** open | Yes |
| **Wake mouth crossfade** (&lt; 1) | Yes |

When Orby returns to `awake`, scheduling resumes from the **same** `nextEligibleAt` (if it already passed, the next eligible tick can fire soon).

Showing Orby (`noteShow`) still **resets** the scheduler (fresh initial delay).

### Picking a behavior

**Weighted random** among behaviors allowed for the current **context** (phase, hover, sleep proximity) — **not** filtered by resolved mood. Gaze-only behaviors are intentionally low weight; visible mouth/overlay behaviors (`tonguePeek`, `bubbleBlow`, …) are strongly weighted. **Stylized** beats (weight **16**) share a cooldown bucket. The immediately previous behavior is excluded when another eligible behavior exists. Mood scales **scheduling interval** only (`scheduleMultiplier`), not which behavior is picked.

### Other gates

- Cursor on orb / `hoverExcited`: no new microbehavior; active microbehavior is canceled into hover. Only **subtle** behaviors (`microSmile`, `eyeWander`, `glanceAround`, `humPulse`) may run under hover if scheduling were allowed — stylized/playful beats are blocked.
- If no behavior is eligible, retry in ~10–18 s.
- &lt; 8 s until sleep: only `humPulse`, `pixelShiver`, `microSmile`; &lt; 4 s: skip scheduling.

## Behaviors (20)

### Base (14)

`microSmile`, `eyeWander`, `glanceAround`, `humPulse`, `selfPolish`, `tonguePeek`, `bubbleBlow`, `cheekPuff`, `tinyYawn`, `sleepyNod`, `sparkleCatch`, `sideEye`, `tinySneeze`, `pixelShiver`.

### Stylized character beats (5)

`animeSelfSatisfied`, `noirDetective`, `cosmicCometWatch`, `catMode`, `blackHoleNibble` — share min **7 min** gap, max **4/hour**, never consecutive. Overlays: anime/cat stylized eyes, noir grading + light band, comet crossing orb, black hole + nibbled star.

### Orbital moment (1)

`saturnRingOrbit` — rare **5–7 s** tilted Saturn-like rings + orbiting satellite around the orb; **no facial reaction**; own cooldown bucket (**35 min** min gap, **1/hour**). Weight **1** (very rare). Suppressed during focus/deepFocus/passive/muted/alarmed/overloaded/disconnected and when cursor is on orb. Rings extend outside orb circle; **hit testing remains orb-only**.

Mouth: always one morphing blob. Tongue/bubble/sparkle are **overlays**, not a second mouth.

## Post-drag dazed

Triggered only by **throw-like** gesture classifier ([Orby_DRAG_DAZED.md](Orby_DRAG_DAZED.md)). Normal reposition does not daze. Dazed **pauses** the micro timer for the whole dizzy phase.

## Code map

| File | Role |
|------|------|
| `OrbyIdleMicrobehavior.swift` | Enum + frame/overlay types |
| `OrbyIdleMicrobehaviorPolicy.swift` | Eligibility + `schedulingSuspended` |
| `OrbyIdleMicrobehaviorWeights.swift` | Weighted random pick |
| `OrbyIdleMicrobehaviorScheduler.swift` | When / pause / rate limits / stylized bucket |
| `OrbyIdleMicrobehaviorAnimation.swift` | Per-behavior curves |
| `OrbyIdleMicroOverlayViews.swift`, `OrbyStylizedEyeViews.swift`, `OrbyStylizedSkyOverlays.swift`, `OrbySaturnRingView.swift` | Overlays |
| `ShrineMiniVisualController.swift` | Tick + gaze gate + merge |
| `NoxTests/Mac/OrbyIdleMicrobehavior*.swift` | Scheduler, policy |
