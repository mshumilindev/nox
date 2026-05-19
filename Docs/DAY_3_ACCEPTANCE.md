# Day 3 Acceptance — Local Activity Awareness + Live Timeline

## Activity observer

- [x] Native `NoxActivityObserver` (NSWorkspace + idle sampling every 2s)
- [x] Active app name + bundle id
- [x] Window title when Accessibility granted
- [x] App/window switch events
- [x] Idle / active transitions
- [x] Wake/sleep + screen lock/unlock signals
- [x] No 50ms polling; observer separated from UI

## Permissions

- [x] Accessibility + Screen Recording state
- [x] Honest limited mode in UI
- [x] Open System Settings + Retry
- [x] No crash without permissions

## Event bus

- [x] Central `NoxEventBus` with typed payloads
- [x] UI reads derived `AppEnvironment` state only

## Persistence

- [x] SQLite timeline store in Application Support
- [x] Events survive restart
- [x] Duplicate `app.changed` suppressed (3s window)
- [x] Prune events older than 30 days

## Presence engine

- [x] Derived states: quiet, active, focused, distracted, idle, resting, flow, limited
- [x] Rules in `NoxPresenceRules` + `NoxPresenceEngine`
- [x] Live badge + card updates

## Sessions

- [x] Rule-based work sessions (5m start, 10m idle/non-productive end)
- [x] Session summary line in UI
- [x] Session events in timeline

## Timeline UI

- [x] Real events (no skeleton fake data)
- [x] Human-readable copy
- [x] Last 50 events
- [x] Empty state only when truly empty

## Constraints

- [x] No AI / cloud / chat
- [x] No fake demo data
- [x] Day 1–2 UI preserved and extended
- [x] Build + unit tests pass
