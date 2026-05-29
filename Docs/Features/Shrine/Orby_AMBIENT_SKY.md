# Orby — Ambient Internal Sky Events

**Parent:** [Orby.md](Orby.md) · **Related:** [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md), [Orby_IDLE_MICROBEHAVIOR.md](Orby_IDLE_MICROBEHAVIOR.md)

## Purpose

Passive visual events **inside** Orby’s cosmic material — occasional meteors and rare Perseid-style showers. Orby **does not react** (no mood, eyes, mouth, or microbehavior coupling).

**Not** the same as:

| Event | Layer | Orby reacts? |
|-------|--------|----------------|
| `ambientMeteor` / `perseidShower` | Internal sky material | **No** |
| `cosmicCometWatch` | Idle microbehavior | **Yes** (tracks comet, “o” mouth) |
| Post-drag dazed stars | External halo | N/A (phase-driven) |
| Static starfield | Internal sky | N/A |

## Layer order

Inside `OrbyCosmicMaterialView` (clipped to circle):

1. Base body fill (day/night gradient)
2. Nebula
3. Static starfield
4. **Ambient meteor layer** (`OrbyAmbientMeteorLayerView`)
5. Inner vignette / day sky / sun
6. Face (above shell in `OrbyOrbChrome`)

Meteors render **below** eyes/mouth; no hit testing.

## Single meteor

- Fast thin streak: head 1–2.2 pt + tapered tail 12–28 pt
- Colors: pale lavender (default), occasional pale cyan / very rare pale rose
- Duration **0.35–0.9 s** (typical ~0.55 s)
- Diagonal paths across orb interior (normalized start/end on/near circle)

## Perseid shower

- **4–9** meteors over **~3.5 s**, staggered 0.15–0.7 s
- Shared radiant (upper-left or upper-right); paths vary ±8–18°
- **Night / twilight only:** `dayNightBlend < 0.65`
- Max **1 per session** (re-arm after 45–90 min cooldown for long sessions)

## Scheduling (`OrbyAmbientSkyEventScheduler`)

Independent of idle microbehaviors and mood.

| Constant | Value |
|----------|--------|
| First meteor after show | 60–120 s |
| Meteor interval | 180–480 s (~4–6 min avg) |
| Min gap between meteors | 90 s |
| Max meteors / 10 min | 3 |
| Perseid initial delay | 10 min |
| Perseid interval | 45–90 min |

**Suppressed** (no new events): dragging, postDragDazed, wake ritual, launch greeting, context menu, active stylized microbehavior (`cosmicCometWatch`, `saturnRingOrbit`, …). Active streaks fade quickly if a busy state starts.

**Allowed but dimmed:** asleep (opacity ×0.62), strong Zzz, day mode (`opacity × lerp(1.0, 0.30, dayNightBlend)`).

## Code map

| File | Role |
|------|------|
| `OrbyAmbientSkyEvent.swift` | Models + render item |
| `OrbyAmbientSkyEventPolicy.swift` | Suppression + opacity multipliers |
| `OrbyMeteorPathGenerator.swift` | Path + Perseid cluster |
| `OrbyAmbientSkyEventScheduler.swift` | Random scheduling |
| `OrbyAmbientMeteorLayerView.swift` | Canvas render |
| `ShrineMiniVisualController.swift` | Tick + `presentation.ambientSkyMeteors` |

## Debug

`#if DEBUG`: `OrbyAmbientSkyEventScheduler.debugTriggerMeteor()` / `debugTriggerPerseid()`.
