# Presence Mesh — Dev Testing

## Shrine capability plan

Shrine is planned as a Presence Mesh-aware ambient surface layer. Existing Presence Mesh behavior remains unchanged today.

Future Shrine integration should add:

- Shrine surface descriptor metadata during pairing/heartbeat.
- Capability lists such as `display.pixelFace`, `audio.soundEffects`, `input.dismiss`, `surface.floatingBubble`, and `constellation.securePairing`.
- Heartbeat freshness for trusted physical Shrine primary eligibility.
- Dev simulator for a Raspberry Pi Shrine descriptor.
- Compatibility tests proving existing Mac-to-Mac mesh pairing still works.

Physical Shrine must be capability-based. Nox must never assume modules from a device model name.

## Two nodes on one Mac

1. Build Nox: `xcodebuild -scheme Nox -destination 'platform=macOS' -configuration Debug build`
2. Run **node A** (terminal 1):
   ```bash
   NOX_PROFILE=node-a open ~/Library/Developer/Xcode/DerivedData/Nox-*/Build/Products/Debug/Nox.app --args -nox-profile node-a
   ```
3. Run **node B** (terminal 2):
   ```bash
   NOX_PROFILE=node-b open ~/Library/Developer/Xcode/DerivedData/Nox-*/Build/Products/Debug/Nox.app --args -nox-profile node-b
   ```
4. In each instance: **Local → Ecosystem → Presence Mesh**.
5. On node B, use **Manual connect**: host `127.0.0.1`, port `9121`, device ID/name from node A’s “This Nox node” section (copy device ID from dev diagnostics or share invite).
6. On node A, tap **Allow** when the join request appears.
7. Send **test pulse** from either trusted node — the other shell should show the aurora overlay.

## Two Macs on LAN

1. Run Nox on both Macs (default profile).
2. Grant **local network** permission when macOS prompts.
3. Open Presence Mesh on both; nearby cards should appear within a few seconds.
4. On the joining Mac, tap **Join**; on the primary Mac, **Allow**.
5. Send test pulse to confirm cross-device reaction.

## Share / AirDrop path

1. On primary node, tap **Share pairing invite** and choose AirDrop or Save (Share Sheet).
2. On the other Mac, import via **Import .noxpair invite** or open the `nox://pair?...` link if registered.

## Xcode scheme args

Add to Run → Arguments:

- Environment: `NOX_PROFILE` = `node-a`
- Or launch argument: `-nox-profile node-a`
