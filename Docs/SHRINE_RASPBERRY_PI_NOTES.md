# Shrine Raspberry Pi Notes

Status: future hardware notes.  
Last updated: 2026-05-29

## Boundary

Do not assume the macOS SwiftUI app can run on Raspberry Pi. macOS AppKit/SwiftUI Shrine surfaces are macOS-only.

Shared `NoxShrineCore` models are suitable as JSON/protocol contracts. Future Pi implementation should use a Linux-safe runtime.

Possible runtime shapes:

- Swift daemon + local web/kiosk UI;
- Node/Python runtime + shared JSON protocol;
- daemon for pairing/heartbeat/audio/input plus browser-based pixel face.

## Physical Shrine v0

Minimum hardware vision:

- Raspberry Pi;
- screen;
- pixel face;
- local discovery/pairing;
- capability heartbeat;
- premade sound effects/basic audio output;
- hard dismiss/snooze input.

Pi v0 should not require AI Camera, environment sensors, LED halo, HomePod relay, or local LLM.

## Physical Shrine v2

Possible modules:

- LED halo;
- mmWave presence;
- environment sensors;
- CO2;
- PM2.5;
- temperature;
- humidity;
- light;
- noise;
- UPS/PoE;
- optional AI Camera;
- optional guest recognition;
- optional cat detection;
- optional HomePod relay.

Pi 5 8GB is recommended for AI Camera, identity, or cat detection experiments. 4GB is acceptable only for simpler v0/v1 surfaces.

## Capability-Based Hardware

All hardware must be capability-based. Nox I must never assume all Shrines have the same modules.

Heartbeat should announce:

- surface id;
- node id;
- display name;
- surface kind/form/mode;
- capabilities;
- room hint if available;
- heartbeat timestamp;
- firmware/runtime version later;
- health/freshness later.

## Audio

Local Shrine speaker remains primary for physical Shrine. HomePod relay is optional and should not be treated as a core dependency.

## Camera Rules

Camera is optional, disabled by default, and must follow:

- no raw frame storage;
- no cloud upload by default;
- event-only output;
- guest recognition opt-in;
- cat/person detection as local events;
- no emotion detection;
- neutral unknown-person handling.

## Pairing

Physical Shrine pairing must be explicit and trust-based. Local discovery can advertise candidates, but trusted primary use requires secure pairing.

Presence Mesh integration should add Shrine descriptors and capability metadata without disrupting existing Mac-to-Mac pairing.
