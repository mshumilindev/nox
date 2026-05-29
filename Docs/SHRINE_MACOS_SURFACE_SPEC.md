# Shrine macOS Surface Specification

Status: planned.  
Last updated: 2026-05-29

## Goal

macOS Software Shrine provides Nox with an ambient body when no trusted physical Shrine is primary. It includes Notch Shrine, Floating Mini Bubble, and Full Shrine Interface.

The next implementation prompt should be:

> Implement macOS Software Shrine MVP: menu entries + Notch Shrine MVP + Floating Mini Bubble MVP + Full Shrine Interface placeholder.

## Menu Bar Entries

Add entries without breaking existing menu bar behavior:

- Open Shrine
- Show Mini Shrine
- Show Notch Shrine, when available
- Hide Shrine
- Disable Shrine Sounds
- Shrine Settings
- Reset Shrine Position

These actions should connect to a macOS `ShrineSurfaceController`, not directly instantiate random windows from menu rows.

## Notch Shrine

MacBook notch support is custom overlay/panel work. There is no native Dynamic Island API for Mac.

MVP behavior:

- detect whether the active internal display appears notch-capable;
- render a compact pixel face near the notch/menu bar area;
- expand briefly for notice/interrupt packets;
- collapse automatically;
- avoid stealing focus;
- hide or become passive during fullscreen/video when policy says so;
- fall back to Floating Mini Bubble if unsafe.

Risk checks:

- menu bar item crowding;
- external display as primary;
- display scale;
- multiple displays;
- screen sharing/presentation;
- fullscreen apps.

## Floating Mini Bubble

MVP behavior:

- small always-on-top AppKit panel with SwiftUI content;
- pixel face only in idle mini mode;
- draggable;
- position remembered per display;
- clamped to visible/safe bounds;
- contextual quick actions;
- click opens Full Shrine Interface;
- dismiss and snooze actions;
- no Dock presence;
- no unnecessary focus steal.

State:

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

Animations:

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

## Full Shrine Interface

Full Shrine is a real surface, but must remain narrow and calm. It is not the Observatory and not a dashboard.

MVP content:

- large pixel face;
- current Shrine state;
- current Nox mode/context;
- one relevant card if any;
- dismiss/snooze/confirm;
- mute;
- physical/software surface indicator;
- Constellation surface status;
- DEBUG-only diagnostic panel.

Layout must avoid macOS-only assumptions so the same model can later feed a Raspberry Pi kiosk or web fullscreen UI.

## Auto-Summon Controller

Allowed trigger families:

- system-state contradiction;
- focus mismatch;
- alarms/time-sensitive events;
- important Constellation state change;
- physical Shrine disconnected.

Forbidden trigger families:

- raw app switches;
- routine messages;
- low-confidence inference;
- generic motivation;
- AI commentary without deterministic trigger.

The controller must check:

- Focus/DND;
- Shrine mute;
- notification gate;
- fullscreen/video policy;
- physical Shrine primary status;
- user dismissal cooldown;
- confidence threshold.

## Video Awareness v0

MVP detection:

- active app bundle id;
- fullscreen or screen-covering window;
- known media/player bundle ids;
- browser fullscreen heuristics when available;
- screen lock/display sleep state if already exposed.

Behavior:

- high confidence: hide or become passive;
- medium confidence: fade or move to corner;
- low confidence: remain visible in safe area.

Add setting: Show Shrine over fullscreen.

## Safe Zone v0

MVP safe zones:

- visible screen bounds;
- menu bar;
- Dock;
- notch region when known;
- edge padding;
- fullscreen hiding.

Later:

- cursor avoidance;
- active window center avoidance;
- toolbar and media control avoidance;
- focused field/caret avoidance;
- Accessibility API v2 behind explicit permission.

## Sound

Use premade sound cues first:

- softPing
- confirm
- dismiss
- alarmGentle
- alarmStrong
- guestHello
- attention
- physicalShrineConnected
- physicalShrineLost

Primary surface may play sound. Mirror/passive surfaces stay silent.

## Non-Goals For MVP

- no full visual Shrine implementation before contracts/specs;
- no free-form chat;
- no voice LLM;
- no camera;
- no Accessibility collision engine by default;
- no physical Pi runtime requirement;
- no full Observatory content inside Shrine.
