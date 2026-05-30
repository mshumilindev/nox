# Orby — Emotional State & Animation Matrix (Amendment)

**Parent:** [Orby.md](Orby.md) · **Status:** Spec + phased implementation (macOS Mini Shrine)

## Purpose

Extends Orby’s emotional/visual language for Shrine features: focus, contradictions, sleep, drag, notifications, alarms, physical Shrine, Pi, Notch — without making Orby a separate assistant or psychological diagnostician.

**Orby emotion = expressive UI state from Nox context**, not a literal mind-reading claim.

## Core design rule

Every emotion combines up to **11 channels**:

1. Eyes · 2. Mouth · 3. Eyelids/brows · 4. Orb tint · 5. Bezel · 6. Glow/shadow · 7. Micro-motion · 8. Particles · 9. Breathing/pulse · 10. Head turn · 11. Timing

No single-icon swaps. One morphing mouth (`OrbyMouthView`). Tint/bezel interpolate (0.15–0.5s).

## State layering

| Layer | Lifetime | Examples |
|-------|----------|----------|
| **Base mood** | Longer | neutral, focused, deepFocus, pleased, curious, concerned, tired, passive, disconnected, … |
| **Temporary expression** | Short | hoverExcited, dragSurprised, postDragDazed, waking*, startled |
| **Intensity** | Modifier | `OrbyEmotionIntensity`: subtle · normal · strong · extreme |

Example: `annoyed(.strong)` → red tint + narrowed eyes + optional steam; `annoyed(.extreme)` → brief steam, decay to annoyed/concerned.

## Principles

- **Cute, not creepy** — even anger = tiny offended kettle, not horror.
- **Readable at ~76pt** — no micro text, no realistic anatomy.
- **Sparse particles** — Zzz, dazed halo, steam (anger), sparks (overload), glints (pleased), thought dots (thinking), alarm ring — phase-bound only.

## Awake eye heights (shipped)

Phase `.awake`, intensity `.normal`, `OrbyEmotionCompositor` — heights in pt before `OrbyEyeMetrics.sizeScale` (**1.08**). Width **9.5**, spacing **16** for all moods below.

| Mood | L ↕ | R ↕ | Notes |
|------|-----|-----|-------|
| neutral | 9.5 | 7.5 | Canonical calm asymmetry |
| passive | 8.5 | 6.8 | Quieter presence |
| muted | 8.0 | 6.5 | Lower energy |
| curious | 10.5 | 8.5 | Open, lively interest |
| focused | 6.0 | 5.5 | Narrow focus |
| deepFocus | 5.5 | 5.0 | Deep flow |
| pleased | 9.0 | 9.0 | Even warm eyes |
| thinking | 8.5 | 7.5 | Reflective |
| concerned | 9.5 | 7.5 | Worried |
| skeptical | 6.5 | 8.0 | R eye taller |
| annoyed | 7.5 | 7.0 | Irritated |
| alarmed | 11.0 | 10.0 | Wide alert |
| sleepy / tired | 5.5 | 5.0 | Heavy |
| disconnected | 7.0 | 6.5 | + `eyesDimmed` |
| overloaded | 10.0 | 9.5 | Stressed |
| nightWatch | 6.0 | 5.5 | Night calm |

`hoverExcited` / `.excited` mood: **11 / 10**. Phases (drag, sleep, dazed, greeting) override — see [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md).

## Matrix (summary)

Full behavioral notes per state are in product spec; implementation maps via `OrbyEmotionCompositor`.

| # | State | Role |
|---|--------|------|
| 1 | neutral | Default calm; eyes **9.5 / 7.5** |
| 2 | focused | Coherent work |
| 3 | deepFocus | Strong flow / low interruption |
| 4 | pleased | Good continuity |
| 5 | excited | `hoverExcited` phase: **surprised “o” mouth** + cheek blush + larger eyes ([Orby_CHEEK_BLUSH.md](Orby_CHEEK_BLUSH.md)) |
| 6 | curious | Ambiguous context; eyes **10.5 / 8.5** |
| 7 | thinking | Short local wait |
| 8 | concerned | Mild mismatch |
| 9 | skeptical | “Really?” |
| 10 | annoyed | Cartoon irritation |
| 11 | angry | Rare; red + steam (intensity) |
| 12 | furious | Debug/meme; decays fast |
| 13 | alarmed | Urgent attention |
| 14 | startled | Brief surprise |
| 15 | dragSurprised | Phase: dragging |
| 16 | postDragDazed | Phase: after drag |
| 17 | tired | Resolved tired (not asleep) |
| 18 | sleepyTransition | Phase: cursor idle |
| 19 | asleep | Phase: full sleep |
| 20 | waking | Phase sequence |
| 21–40 | confused, lost, disconnected, glitch, waiting, notifying, celebrating, protective, melting, suspicious, embarrassed, proud, coldQuiet, alarmGentle/Strong, ritual | Later tiers |
| — | passive, muted, overloaded, nightWatch | Shipped base moods (see eye table above) |

## Color / tint categories

| Category | Use |
|----------|-----|
| Default purple/graphite | neutral |
| Cool indigo | focus, deepFocus, nightWatch |
| Warm rose/gold | pleased, celebrating, proud |
| Amber | concern, gentle alarm |
| Red overlay | annoyed, angry (layered on purple) |
| Cyan | curious, thinking |
| Desaturated gray | disconnected, muted, lost |

## Particles (allowed)

Zzz · dazed rings/stars · steam (anger strong+) · sparks (overload) · glints (pleased) · thought dots (thinking) · alarm ring · rare glitch pixels

Forbidden: confetti storms, constant particles, screen sampling.

## Implementation priority

### Shipped / current code path

neutral, focused, pleased, concerned, curious, annoyed, alarmed, passive, muted, disconnected, tired, deepFocus, skeptical, thinking, overloaded, nightWatch, hoverExcited, drag/postDragDazed, sleepy/asleep/waking.

### Next

notifying, celebrating, startled burst, angry/furious intensity on annoyed.

### Later

lost, glitch, embarrassed, proud, protective, coldQuiet, alarms, ritual, melting, suspicious, …

## Code map

| File | Role |
|------|------|
| `OrbyEmotionIntensity.swift` | Intensity enum + resolver |
| `OrbyEmotionAppearance.swift` | Eyes (canonical layout), tint, bezel, particles |
| `OrbyEmotionCompositor.swift` | mood + intensity + phase → appearance |
| `OrbyParticleOverlayView.swift` | Steam, sparks, glints, thoughts |
| `ShrineMoodResolver.swift` | Base mood from Nox signals |
| `ShrineMiniVisualController.swift` | Phases + compositor merge |

## Acceptance (matrix)

1. Broad matrix documented; emotions are UI states not AI.  
2. Each implemented mood uses eyes + mouth + tint + bezel (+ optional particles).  
3. Negative states stay stylized/cute.  
4. Anger uses brief red + steam at strong/extreme only.  
5. Sleep/wake/drag/hover/cursor core behavior preserved.
6. Cursor movement during `sleepyTransition` (before `asleep`) cancels transition immediately — no full wake ritual.  
6. One morphing mouth; animated tint/bezel.  
7. No new tracking, camera, screen recording, or permissions.  
8. New moods addable without breaking MVP.
