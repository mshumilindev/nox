# Shrine Architecture

Status: planned architecture with minimal core contracts added.  
Last updated: 2026-05-29

## Layering

Shrine follows the existing Nox platform rule: Apps depend on Packages; Packages do not depend on Apps.

```
Packages/
  NoxShrineCore/          # Foundation-only Shrine contracts
Apps/
  NoxMac/Nox/
    Core/Shrine/          # future AppKit/SwiftUI/macOS adapters
    Features/Shrine/      # future Shrine views
Physical Shrine runtime/  # future Linux-safe runtime, not the macOS app
```

`NoxShrineCore` must not import SwiftUI, AppKit, UIKit, Combine UI adapters, or persistence implementations. It should contain Codable/Sendable contracts and pure policy services only.

## Core Contracts

Initial package: `Packages/NoxShrineCore`.

Added contracts:

- `NoxShrineSurfaceKind`: software, physical.
- `NoxShrineSurfaceMode`: primary, mirror, passive, disabled.
- `NoxShrineSurfaceForm`: notch, floatingBubble, fullInterface, physicalDisplay, passiveMirror.
- `NoxShrineCapability`: display, audio, input, expression, presence, vision, identity, environment, constellation, surface, and optional AI capabilities.
- `NoxShrineFaceState`: idle, focused, sleepy, concerned, alarmed, pleased, annoyed, disconnected, passive, muted, physicalShrineActive.
- `NoxShrineAnimation`: none, blink, lookAround, wake, sleepBreath, sideEye, glitch, softPulse, attentionPulse, dismissShrink, dragSquish.
- `NoxShrineSoundCue`: none, softPing, confirm, dismiss, alarmGentle, alarmStrong, guestHello, attention, physicalShrineConnected, physicalShrineLost.
- `NoxShrineUrgency`: ambient, notice, interrupt.
- `NoxShrineAction`: dismiss, snooze, confirm, switchFocus, openNox, openFullShrine, muteShrine, hideShrine.
- `NoxShrineBehaviorPacket`: face state, animation, sound, optional text, urgency, actions.
- `NoxShrineSurfaceDescriptor`: surface identity, node identity, kind/form/mode, capabilities, physical proximity, heartbeat, room hint.
- `NoxShrineEventType` and `NoxShrineEvent`: local event stream for user corrections, surface transitions, presence/sensor events, and UI events.

These contracts are JSON-friendly so macOS, future iOS/tvOS surfaces, and Raspberry Pi runtimes can speak the same protocol even if they are not all SwiftUI apps.

## Future Core Services

The following should remain pure and testable:

- `NoxShrineSurfaceSelectionService`
- `NoxShrineBehaviorProvider`
- `NoxDeterministicShrineBehaviorProvider`
- `NoxShrineUserCorrectionModel`
- `NoxShrineNotificationGate`
- `NoxShrineSurfacePolicy`

Optional later:

- `NoxOllamaShrineBehaviorProvider` as an adapter or optional module, disabled by default.

## macOS Adapter Layer

Future macOS implementation should live under the app target, not in `NoxShrineCore`.

Planned controllers/services:

- `ShrineMiniPanelController`
- `ShrineNotchPanelController`
- `ShrineFullWindowController`
- `ShrineSurfaceController`
- `ShrineAutoSummonController`
- `ShrineSafeZoneEngine`
- `ShrineVideoAwarenessService`
- `ShrineSoundCuePlayer`
- `ShrineBehaviorStore`
- `ShrineSurfaceSelectionService` if it needs macOS display/window inputs

Planned SwiftUI views:

- `ShrineMiniFaceView`
- `ShrineNotchFaceView`
- `ShrineFullSurfaceView`
- `ShrineActionStripView`
- `ShrineStatusCardView`
- `ShrineDebugPanelView` in DEBUG only

Mini and Notch surfaces should not steal focus. Full interface may be focusable when opened manually. Mini bubble should not appear in the Dock. Notch overlay must be a Nox-owned panel, not a presumed system Dynamic Island API.

## Presence Mesh Integration

Physical Shrine and software surfaces should use Presence Mesh concepts without breaking current mesh behavior.

Future mesh additions:

- Shrine surface descriptors in heartbeat metadata.
- Capability list during pairing and heartbeat.
- Freshness threshold for physical Shrine availability.
- One-primary-surface arbitration.
- Simulator/dev mode for physical Shrine descriptors.

Physical Shrine is trusted only after explicit pairing. Nox I must never infer capability from model name; it reads capabilities from descriptors.

## Surface Selection Policy

Inputs:

- current node role;
- trusted physical Shrine availability;
- user preferred surface form;
- current display/notch availability;
- menu bar crowding risk if detectable;
- active fullscreen/video state;
- user correction history;
- current Focus/mute settings;
- Station eligibility;
- heartbeat freshness.

Outputs:

- primary surface;
- mirror surfaces;
- passive surfaces;
- disabled surfaces;
- selected surface form;
- reason.

Default priority:

1. nearby trusted physical Shrine;
2. Notch Shrine on notched MacBook if safe and preferred/automatic;
3. Floating Bubble on Nox I;
4. Software Shrine on Satellite;
5. Station only if explicitly enabled;
6. no Shrine.

Invariant: only one primary sound-capable surface.

## Behavior Packets

Shrine behavior is expressed as packets, not arbitrary imperative commands. A packet may request a face state, animation, sound cue, urgency, optional short text, and allowed actions.

AI providers, if introduced, may only propose structured packets. They must not bypass deterministic trigger gates, directly control hardware, or produce long monologues.

## Storage

Shrine does not own canonical memory. Local storage should be limited to:

- surface preferences;
- sound/mute settings;
- user correction counters;
- last known bubble positions per display;
- recent dismissal cooldowns;
- surface descriptors and heartbeat cache;
- display/audio fallback cache when needed.

Shrine must not store Galaxy, Deep Space, raw video, raw frames, or long-term personal identity data.

## Validation

Current core validation:

```bash
swift test --package-path Packages/NoxShrineCore
```

Future validation:

- Codable roundtrip tests for all contracts.
- Surface selection invariants.
- Multiple-primary prevention.
- Physical fallback tests.
- Fullscreen/video behavior tests.
- Presence Mesh compatibility tests.
- Privacy/no-surveillance tests.
