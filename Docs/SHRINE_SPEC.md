# Nox Shrine Specification

Status: planned architecture, implementation-ready spec.  
Last updated: 2026-05-29

## Definition

Nox Shrine is the ambient visual and presence body of Nox. It is not only a Raspberry Pi device and not only a macOS widget. Shrine is an embodiment layer that can appear through different Shrine Surfaces.

Canonical product rule:

> Nox Shrine is allowed to be alive. It is not allowed to be needy.

Shrine must be glanceable before readable, expressive before talkative, useful before clever, and silent by default. It must not become a chatbot, full dashboard, productivity scold, notification spammer, surveillance box, or free-form voice assistant.

## Product Direction

The target hardware vision is Shrine v2, but implementation begins as Shrine v0. The architecture must be v2-ready from day one while the first prototype remains minimal.

Physical Shrine is the preferred dedicated body when a nearby trusted device is available. Software Shrine is the required fallback body on existing Nox nodes when no nearby trusted physical Shrine is available.

Shrine may run on:

- Nox I: default eligible software fallback and primary controller.
- Nox Satellite: possible software Shrine fallback or passive/mirror surface.
- Nox Station: tentative only; must be explicitly enabled and must not be assumed by default.
- Physical Shrine: preferred primary body when trusted, nearby, and fresh.

## Surface Model

Every Shrine appearance is a Shrine Surface. A surface has:

- `surfaceKind`: software or physical.
- `surfaceForm`: notch, floatingBubble, fullInterface, physicalDisplay, passiveMirror.
- `surfaceMode`: primary, mirror, passive, or disabled.
- capabilities announced at pairing and heartbeat.

Only one Shrine Surface should be primary at once. The primary surface may play sound and intervene. Mirror surfaces may show state silently. Passive surfaces may only show ambient state. Disabled surfaces do nothing.

Default priority:

1. Nearby trusted physical Shrine with fresh heartbeat.
2. Notch Shrine on a notched MacBook if safe and preferred/automatic.
3. Floating Mini Bubble on Nox I.
4. Software Shrine on Satellite.
5. Station Shrine only when explicitly enabled.
6. No Shrine.

If physical Shrine is primary, macOS Software Shrine should usually become passive, mirrored, hidden, or control-only depending on user preference. If physical Shrine disappears, macOS Software Shrine may become primary fallback.

## Software Shrine

Software Shrine is core, not optional decoration. It can be launched manually from the Nox menu bar/tray dropdown and can auto-summon when Nox needs to notify or intervene.

Software Shrine forms:

- Notch Shrine: compact notch-aware macOS overlay.
- Floating Mini Bubble: small floating pixel-face surface.
- Full Shrine Interface: reusable full surface that can later adapt to physical displays.

Software Shrine must respect mute settings, Focus/DND, video/fullscreen state, physical Shrine primary status, user dismissal cooldown, confidence threshold, and notification gates.

## Notch Shrine

On MacBook models with a notch, Nox should support a notch-aware Software Shrine mode. MacBook Pro M4 notch is not a native Dynamic Island. It is a physical camera notch in the menu bar, and macOS does not provide a public Dynamic Island API for Mac.

Therefore Notch Shrine must be implemented as a Nox-owned custom overlay/panel around or below the notch area. It should be the preferred macOS Software Shrine form on notched MacBooks when it is less intrusive than a floating bubble.

Notch Shrine should:

- visually live around the notch/menu bar area;
- show a tiny pixel face or compact Shrine state;
- expand temporarily for relevant notices;
- collapse back to quiet presence;
- avoid hiding important menu bar items;
- account for display scale, multiple displays, external displays without notches, fullscreen apps, screen sharing, presentation mode, and user preference.

If Notch Shrine is impossible, intrusive, unavailable, or unsafe, Nox falls back to Floating Mini Bubble.

## Floating Mini Bubble

Mini Shrine Bubble is a small floating always-on-top pixel-face surface. It shows a living pixel face, stays above normal windows, can be dragged by the user, remembers position, can be temporarily dismissed, can be pinned/unpinned, opens Full Shrine Interface on click, and opens quick actions on contextual click.

It should not steal focus unnecessarily, behave like a normal document window, appear as a separate Dock app, or feel like a chat-head clone.

Visual principles:

- small and quiet;
- pixel face first;
- no large text in mini mode;
- no heavy glow by default;
- no large notification panel unless expanded;
- state conveyed through face, animation, tiny cue, or optional badge.

Mini states:

- idle
- focused
- sleepy
- concerned
- alarmed
- pleased
- annoyed
- disconnected
- passive
- muted
- physicalShrineActive

Mini animations:

- blink
- lookAround
- wake
- sleepBreath
- sideEye
- glitch
- softPulse
- attentionPulse
- dismissShrink
- dragSquish

## Surface Selection And Adaptation

Settings:

- Preferred Shrine Surface: Automatic, Notch, Floating Bubble, Hidden unless needed, Physical only.
- Auto-adapt Shrine placement/form based on user corrections.

Local correction signals:

- `draggedCount`
- `dismissedCount`
- `manuallyHiddenCount`
- `notchDisabledCount`
- `bubblePinned`
- `lastPreferredSurfaceForm`

Nox must not overfit after one drag. Automatic switches require thresholds and cooldowns. Every automatic switch must be explainable, reversible, and user-controllable.

Selection may switch from Floating Bubble to Notch Shrine when notch mode is safe and the bubble appears intrusive. It may switch from Notch Shrine to Floating Bubble when notch mode is frequently dismissed, expanded, or hidden.

## Drag And Positioning

Floating Bubble must support drag and remember position per display. It cannot get lost off-screen and should avoid menu bar, Dock, notch, and inaccessible screen edges.

MVP:

- drag anywhere reasonable;
- clamp to safe bounds;
- remember position per display;
- handle display disconnect/reconnect;
- provide reset position action;
- hide/fade in obvious fullscreen contexts if enabled.

Later:

- magnetic safe-zone snapping;
- cursor avoidance;
- active UI avoidance;
- focused text field/caret avoidance;
- toolbar avoidance;
- media controls avoidance;
- intelligent lower-interference movement.

If the bubble is pinned, Nox must not aggressively move it unless it would be off-screen or a critical fullscreen/video policy applies.

## Auto-Summon

Allowed triggers:

- focus contradiction;
- Sleep Focus active while active work is detected;
- Work Focus active during obvious fade-out;
- alarm;
- calendar pressure;
- important Constellation state change;
- physical Shrine disconnected;
- attention-worthy system-state contradiction.

Forbidden triggers:

- every app switch;
- every email;
- every Slack/Telegram ping;
- low-confidence inference;
- generic motivation;
- AI-generated commentary without deterministic trigger.

Modes:

- ambient: face wakes/appears only.
- notice: compact animation and optional sound cue.
- interrupt: compact card/full expansion only for alarms or high-confidence time-sensitive events.

## Full Shrine Interface

Clicking Notch Shrine or Floating Bubble opens Full Shrine Interface. This is the conceptual UI that can later run on or be adapted to Raspberry Pi. It must not be macOS-only in layout assumptions.

Full Shrine should include:

- large pixel face;
- current Shrine state;
- current Nox mode/context;
- one relevant card if any;
- dismiss/snooze/confirm actions;
- sound mute;
- physical/software surface indicator;
- Constellation surface status;
- optional debug section in DEBUG only.

Full Shrine must not become full Observatory, a dashboard, full chat, settings-heavy control panel, or timeline browser. It must be driven by `NoxShrineState`/`NoxShrineBehaviorPacket`-style models, with the same model later feeding Raspberry Pi kiosk/web/fullscreen UI.

## Video, Fullscreen, And Non-Intrusion

Software Shrine should not sit over video or fullscreen contexts when inappropriate. MVP should detect obvious fullscreen windows/apps and hide, fade, or collapse Shrine if enabled.

Setting:

- Show Shrine over fullscreen.

Signals may include active app bundle id, fullscreen window frame, screen-covering window, known media apps, browser fullscreen heuristics, display sleep/lock, Focus state, Now Playing metadata later, and user manual hide.

Policy:

- high confidence fullscreen/video: hide or move to passive invisible edge.
- medium confidence: reduce opacity or move to corner.
- low confidence: stay visible but avoid center and active UI zones.

Avoid appearing over screen sharing or presentation modes if detectable.

## Collision Avoidance

v0:

- manual drag;
- remember position;
- avoid Dock/menu bar/notch;
- basic edge safe zones;
- fullscreen hide.

v1:

- simple SafeZoneEngine;
- move away from cursor;
- avoid center of active window;
- avoid top toolbar/menu zones;
- avoid bottom media controls;
- move away from active text insertion area if available.

v2:

- Accessibility API-based detection of active window frame, focused UI element frame, buttons/text fields when accessible, scroll/content areas, modal dialogs, sheets/popovers, text insertion focus, and important active controls.

SafeZoneEngine inputs:

- display bounds;
- menu bar/dock/notch safe areas;
- current surface frame;
- active app bundle id;
- active window frame;
- focused element frame if available;
- cursor position;
- fullscreen/video confidence;
- user pinned state;
- physical Shrine availability;
- urgency.

Outputs:

- desired surface frame;
- movement reason;
- movement urgency;
- shouldHide;
- shouldFade;
- shouldStayPinned.

Accessibility permissions must be explicit and documented. Nox must not request invasive permissions silently.

## Physical Shrine

Physical hardware is capability-based, not model-assumption-based. Nox I must never assume all Shrines have the same modules. Each Shrine announces capabilities during pairing and heartbeat.

Physical Shrine v0:

- Raspberry Pi + screen;
- pixel face;
- local discovery/pairing;
- capability heartbeat;
- premade sound effects/basic audio output;
- hard dismiss/snooze input.

Physical Shrine v2 may add:

- LED halo;
- mmWave presence;
- environment sensors;
- CO2;
- PM2.5;
- UPS/PoE;
- optional AI Camera;
- optional guest recognition;
- optional cat detection;
- optional HomePod relay.

Do not assume the macOS SwiftUI app can be installed directly on Raspberry Pi. Shared ShrineCore can be platform-neutral Swift, but macOS SwiftUI/AppKit cannot run on Pi. Future Pi implementation should use a separate Linux-safe runtime, likely Swift daemon plus web/kiosk UI or Node/Python runtime with shared JSON protocol.

Camera rules:

- optional;
- no raw frame storage;
- no cloud upload by default;
- event-only output;
- guest recognition opt-in;
- cat/person detection as local events.

## AI And Ollama

AI is optional and not required for Shrine MVP. Ollama may be added as a behavior provider, but disabled by default.

AI must generate structured behavior packets only. It must not generate free-form voice, long monologues, direct hardware commands, or bypass notification gates.

Premade sound effects are preferred over generated voice. Voice LLM is explicitly not default because it risks creepiness.

## Privacy And Trust

Shrine does not own canonical memory, does not store Galaxy/Deep Space, and caches only what it needs for display/audio fallback.

User controls:

- disable Shrine;
- disable sounds;
- disable auto-summon;
- disable camera;
- disable guest recognition;
- disable AI behavior generation;
- disable fullscreen overlay.

Defaults:

- trusted surfaces only;
- explicit pairing;
- no raw video storage;
- no cloud vision upload by default;
- no face recognition by default;
- no emotion detection;
- guest recognition opt-in;
- cat detection optional;
- unknown person handling neutral.

Shrine should communicate state, not surveil. It must not say things like “you look sad” or “I saw you doing X”.

## Definition Of Done

- Specs exist and reflect current decisions.
- Notch Shrine and Floating Mini Bubble are explicitly documented.
- Physical Shrine fallback/priority behavior is explicit.
- Full Shrine Interface is reusable/adaptable for Raspberry Pi.
- ShrineCore contracts are platform-neutral and tested if added.
- Existing Nox functionality is not broken.
- No physical Raspberry requirement is introduced.
- No free-form voice LLM is implemented.
- No camera/identity behavior is enabled by default.
- No invasive Accessibility permission is requested without a specific UX reason.
