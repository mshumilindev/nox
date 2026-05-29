# Shrine Platform Breakdown

Status: planned.  
Last updated: 2026-05-29

## macOS Nox I

Role: primary software fallback and canonical controller.

Can host:

- Notch Shrine;
- Floating Mini Bubble;
- Full Shrine Interface;
- physical Shrine pairing/control;
- deterministic behavior provider;
- optional future Ollama behavior provider disabled by default.

Must not break:

- menu bar behavior;
- Presence Mesh;
- Observatory;
- local memory;
- system-state contradiction logic.

## macOS Nox Satellite

Role: possible passive/mirror or fallback Software Shrine.

Can host:

- Floating Mini Bubble;
- Full Shrine Interface;
- passive/mirror state;
- limited primary fallback if explicitly selected and no better surface exists.

Must not own canonical memory.

## Nox Station

Role: tentative. Not default.

Can host Shrine only if explicitly enabled. It may be useful as a passive/mirror or room-like surface, but the product must not assume Station Shrine support.

## Physical Raspberry Pi Shrine

Role: preferred dedicated Shrine body when nearby, trusted, and fresh.

v0:

- screen;
- pixel face;
- local discovery/pairing;
- capability heartbeat;
- premade sounds/basic audio;
- hard dismiss/snooze.

v2:

- LED halo;
- mmWave;
- CO2/PM2.5/temp/humidity/light/noise;
- UPS/PoE;
- optional AI Camera;
- optional guest recognition;
- optional cat detection;
- optional HomePod relay.

Runtime must be separate from the macOS SwiftUI app. Possible approaches:

- Linux-safe Swift daemon + web/kiosk UI;
- Node/Python runtime with shared JSON protocol;
- hybrid daemon plus local browser kiosk.

## iPhone

Role: future Nox Satellite/Shrine Surface. Not MVP.

Possible behavior:

- passive/mirror Shrine face;
- local notification bridge;
- dismiss/snooze/confirm actions;
- no canonical memory ownership.

Permissions must be explicit.

## Apple TV

Role: future passive/mirror room display Shrine Surface. Not MVP.

Good fit:

- large ambient face;
- room state;
- passive/mirror status.

Constraints:

- limited input;
- no canonical memory;
- no primary sound unless explicitly selected.

## HomePod

Role: not a full Nox node.

Possible future use:

- optional audio relay;
- Beacon-like signal;
- Apple ecosystem mediated output through Mac, Shortcuts, Home Assistant, or other bridge.

Do not assume direct reliable Pi-to-HomePod AirPlay. Local Shrine speaker remains primary for physical Shrine.

## Shared Contract

All platforms should speak through `NoxShrineCore` concepts:

- surface descriptor;
- capability list;
- behavior packet;
- event stream;
- surface mode/form;
- primary/mirror/passive/disabled arbitration.
