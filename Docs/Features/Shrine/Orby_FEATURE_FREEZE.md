# Orby — Feature freeze (flying sphere)

| | |
|--|--|
| **Status** | **FROZEN** |
| **Effective** | 2026-05-30 |
| **Scope** | macOS Mini Shrine **floating orb / face** only |
| **Lift** | Only when product explicitly says otherwise |

## What is frozen

Orby as the **always-on-top circular flying sphere**: face, orb material, hover/drag/sleep/wake, launch greeting, idle microbehaviors, menu-bar toggle, placement, and related tests/docs.

Treat the shipped behavior in [Orby.md](Orby.md) and linked topic specs as **complete for v1 of the flying sphere**.

## Allowed without approval

- Bug fixes that restore **documented shipped behavior**
- Test additions/fixes aligned with shipped behavior
- Doc corrections to match code
- Dependency or security fixes with **zero** user-visible Orby change

## Not allowed without explicit approval

- New moods, phases, microbehaviors, or particle systems
- Visual redesign (eyes, mouth, cosmic material, blush, hover expression)
- New interactions, permissions, or persistence
- Full Shrine features wired through the orb beyond existing click → Full Shrine
- iPhone/iPad/other platforms (still governed by [platform boundaries](../../PLATFORM_ARCHITECTURE.md))

## Canonical references while frozen

| Topic | Doc |
|-------|-----|
| Integration overview | [Orby.md](Orby.md) |
| Emotions | [Orby_EMOTION_MATRIX.md](Orby_EMOTION_MATRIX.md) |
| Microbehaviors | [Orby_IDLE_MICROBEHAVIOR.md](Orby_IDLE_MICROBEHAVIOR.md) |
| Visual polish | [Orby_VISUAL_POLISH.md](Orby_VISUAL_POLISH.md) |

## Agent / contributor note

Cursor rule: `.cursor/rules/orby-feature-freeze.mdc` — applies when editing Orby/Shrine mini paths.
