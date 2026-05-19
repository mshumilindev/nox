# Context QA Matrix (Iteration 6A)

Validation is organized by **scenario class**, not by specific apps or sites. Use concrete apps only as optional samples when manually testing.

## Scenario classes

| Class | Automated test | What to validate |
| --- | --- | --- |
| Writing | `writingScenario` | Typing → `writing`, evidence items |
| Coding | `codingScenario` | Editor adapter, development/writing |
| Passive video | `passiveVideoScenario` | YouTube-shaped title + URL → `watching` |
| Streaming site | `streamingSiteScenario` | Entertainment domain → `watching` |
| Browser game | `browserGameScenario` | Active non-writing interaction |
| Desktop game | `desktopGameScenario` | `game` adapter invoked |
| Travel booking | `travelBookingScenario` | Travel/planning candidates |
| Shopping comparison | `shoppingComparisonScenario` | Comparison candidates |
| File transfer | `fileTransferScenario` | `file-transfer` adapter |
| PDF reading | `pdfReadingScenario` | Document shape → reading |
| Private browsing | `privateBrowsingScenario` | Redaction / elevated sensitivity |
| Banking | `bankingScenario` | `Sensitive context` label |
| Missing permissions | `missingPermissionsScenario` | Missing channels as data |
| Unknown app | `unknownAppScenario` | `unknown-fallback` adapter |
| Stale decay | `staleFragmentedYieldsToPassiveMedia` | Passive media dominates fragmented |

Additional manual classes: AI prompt writing, AI response reading, health, private messaging — covered partially by semantic tests in `NoxTests.swift`.

## Per-class checklist

For each class, confirm:

1. **App identity** — name, bundle id, PID when available
2. **Window/context metadata** — respects capability level; missing channels listed
3. **Interaction evidence** — typing/scroll/pointer in evidence items
4. **Dominant context** — single dominant; secondary/stale on sustained shifts
5. **Safe label** — human, short; sensitive → generalized only
6. **Sensitivity** — private/sensitive never leak full title/URL to UI or warm DB
7. **Stale decay** — fragmented workflow does not block sustained passive media
8. **Persistence safety** — only `NoxPersistableContextSnapshot` fields stored long-term
9. **Explainability** — DEBUG panel shows evidence chain

## Adapters (6A registry)

| Adapter ID | Role |
| --- | --- |
| `terminal` | Shell / build workflows |
| `editor` | IDE / editor apps |
| `browser` | Browser-shaped apps |
| `communication` | Messaging / mail |
| `creative-app` | Design / creative tools |
| `media-app` | Native media players |
| `game` | Game / interactive entertainment |
| `file-transfer` | Downloads / transfer-shaped titles |
| `generic-app` | Utility / document / unknown family |
| `unknown-fallback` | Last resort when signals are thin |

## Dev explainability

- Models: `NoxAppContext`, `NoxContextEvidenceItem`, `NoxContextObservationChannel`
- Pipeline: `NoxContextAcquisitionPipeline`, `NoxContextEvidenceAssembler`
- DEBUG UI: `NoxContextExplainabilityView` (dashboard, Debug builds only)
