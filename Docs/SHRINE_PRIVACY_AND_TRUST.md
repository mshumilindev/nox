# Shrine Privacy And Trust

Status: planned.  
Last updated: 2026-05-29

## Principle

Shrine communicates state. It does not surveil.

Shrine must feel alive, quiet, and trustworthy without becoming a monitoring appliance. It should never say creepy or invasive things like “you look sad” or “I saw you doing X”.

## Memory Boundary

Shrine does not own canonical memory and does not store Galaxy or Deep Space. It caches only what it needs for display/audio fallback.

Allowed local Shrine storage:

- surface preferences;
- surface descriptors;
- heartbeat freshness;
- bubble position per display;
- sound/mute settings;
- user correction counters;
- dismiss/snooze cooldowns;
- minimal behavior cache.

Forbidden storage:

- raw frames;
- raw video;
- cloud vision upload by default;
- emotion detection;
- face recognition by default;
- long-term identity store by default;
- copied Observatory timeline;
- canonical Nox memory.

## Pairing And Trust

Only trusted surfaces may become primary. Pairing must be explicit. Physical Shrine announces capabilities during pairing and heartbeat; Nox never assumes modules from a model name.

If trust is stale or heartbeat freshness fails, physical Shrine should lose primary eligibility and macOS Software Shrine may become fallback.

## Camera And Identity

Camera is optional and disabled by default.

Rules:

- no raw frame storage;
- no cloud upload by default;
- event-only output;
- guest recognition opt-in;
- no face recognition by default;
- cat/person detection optional;
- unknown person handling neutral;
- no emotion detection.

## User Controls

Users must be able to disable:

- Shrine entirely;
- Shrine sounds;
- auto-summon;
- fullscreen overlay;
- camera;
- guest recognition;
- AI behavior generation.

Accessibility permissions must have a specific UX reason and must never be requested silently.

## AI Safety

AI is not required for Shrine MVP. If AI is later used, it may generate structured `NoxShrineBehaviorPacket` proposals only.

AI must not:

- bypass deterministic notification gates;
- issue direct hardware commands;
- generate free-form voice;
- produce long monologues;
- infer emotions from visual input;
- claim certainty about private user state.

## Tests To Add

- no raw camera storage path enabled by default;
- guest recognition default off;
- AI behavior provider default off;
- one-primary-surface invariant;
- mirror/passive surfaces do not play sound;
- auto-summon respects cooldowns and Focus/DND;
- fullscreen/video policy hides or fades surfaces when configured;
- Accessibility collision engine remains behind explicit permission.
